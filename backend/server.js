import express from 'express';
import { chromium } from 'playwright';

const app = express();
app.use(express.json());

let browser;
let busy = false;

const normalizeCrp = (value) => {
  const digits = String(value ?? '').replace(/\D/g, '');
  // O tamanho do registro varia entre as regionais: quatro, cinco ou seis
  // dígitos depois do código regional são formatos encontrados no CFP.
  return /^\d{6,8}$/.test(digits) ? `${digits.slice(0, 2)}/${digits.slice(2)}` : null;
};

const normalizeText = (value) => String(value ?? '')
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .replace(/\s+/g, ' ')
  .trim();

const escapeRegExp = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

app.get('/health', (_req, res) => res.json({ ok: true }));

app.post('/validate-crp', async (req, res) => {
  const crp = normalizeCrp(req.body?.crp);
  if (!crp) return res.status(400).json({ exists: false, message: 'CRP inválido.' });
  if (busy) return res.status(429).json({ exists: false, message: 'Já existe uma consulta em andamento.' });

  busy = true;
  let context;
  try {
    browser ??= await chromium.launch({ headless: false });
    context = await browser.newContext();
    const page = await context.newPage();
    await page.goto('https://cadastro.cfp.org.br/', { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.getByRole('button', { name: 'Busca avançada' }).click();
    const regionalCode = String(Number(crp.slice(0, 2)));
    const stateSelect = page.getByRole('combobox', { name: 'Estado' });
    const regionalValue = await stateSelect.locator('option').evaluateAll((options, code) => {
      const option = options.find((item) => String(Number(item.value)) === code);
      return option?.value ?? null;
    }, regionalCode);
    if (!regionalValue) {
      return res.status(400).json({
        exists: false,
        message: `A regional ${crp.slice(0, 2)} não está disponível na lista atual do CFP.`,
      });
    }
    await stateSelect.selectOption(regionalValue);
    await page.getByRole('textbox', { name: 'Número de registro CPF' }).fill(crp.slice(3));

    await page.getByRole('button', { name: 'Buscar' }).click();
    // A busca é assíncrona e o CFP pode levar alguns segundos para atualizar a tela.
    await page.waitForTimeout(8000);

    const registrationNumber = crp.slice(3);
    const registrationPattern = new RegExp(`(?:^|\\s)${escapeRegExp(registrationNumber)}(?:\\s|$)`);
    const tableRows = await page.locator('table tbody tr, main tr').allTextContents().catch(() => []);
    const matchingRow = tableRows.find((row) => registrationPattern.test(normalizeText(row)));
    const rowText = normalizeText(matchingRow);
    const rowParts = rowText.split(/\s{2,}|\t/).filter(Boolean);
    const status = rowParts[0]?.toUpperCase() || '';
    const name = rowParts.length >= 4 ? rowParts[1] : undefined;
    const regional = rowParts.length >= 4 ? rowParts[2] : undefined;

    const text = await page.locator('body').innerText();
    const normalized = normalizeText(text).toLowerCase();
    const registrationDigits = crp.replace(/\D/g, '');
    const pageDigits = text.replace(/\D/g, '');
    const hasRegistration = pageDigits.includes(registrationDigits);
    const notFound = normalized.includes('nenhum profissional') || normalized.includes('nenhum resultado') || normalized.includes('nao encontrado');
    const exists = Boolean(matchingRow) || (!notFound && hasRegistration);

    if (!exists) {
      const captcha = page.locator('iframe[title*="reCAPTCHA"], iframe[src*="recaptcha"]');
      if (await captcha.count()) {
        console.log(`[CFP] CAPTCHA exibido para ${crp}. Resolva na janela aberta e clique em Buscar.`);
        // Mantém a janela aberta para uma resolução manual. Não há bypass
        // automático de CAPTCHA; o usuário precisa concluir a interação.
        // Após cada tentativa, verifica se a tabela foi atualizada.
        for (let attempt = 1; attempt <= 10; attempt += 1) {
          await page.getByRole('button', { name: 'Buscar' }).click().catch(() => {});
          console.log(`[CFP] nova tentativa de busca ${attempt}/10 para ${crp}`);
          await page.waitForTimeout(5000);

          const retryRows = await page.locator('table tbody tr, main tr').allTextContents().catch(() => []);
          const retryRow = retryRows.find((row) => registrationPattern.test(normalizeText(row)));
          if (retryRow) {
            const retryParts = normalizeText(retryRow).split(/\s{2,}|\t/).filter(Boolean);
            const retryStatus = retryParts[0]?.toUpperCase() || 'ATIVO';
            console.log(`[CFP] consulta ${crp}: encontrado após CAPTCHA (${retryStatus})`);
            return res.json({
              exists: true,
              status: retryStatus,
              registration: crp,
              ...(retryParts.length >= 4 ? { name: retryParts[1], regional: retryParts[2] } : {}),
            });
          }
        }

        return res.status(409).json({
          exists: false,
          message: 'O CAPTCHA não foi concluído a tempo. Resolva-o na janela do CFP e tente novamente.',
        });
      }
    }

    console.log(`[CFP] consulta ${crp}: ${exists ? 'encontrado' : 'não encontrado'}${matchingRow ? ` (${status})` : ''}`);
    return res.json({
      exists,
      status: exists ? (status || 'ATIVO') : 'NÃO ENCONTRADO',
      registration: crp,
      ...(name ? { name } : {}),
      ...(regional ? { regional } : {}),
    });
  } catch (error) {
    return res.status(502).json({ exists: false, message: 'Falha ao consultar o cadastro público do CFP.' });
  } finally {
    await context?.close();
    busy = false;
  }
});

app.listen(3000, '127.0.0.1', () => console.log('CFP local scraper em http://127.0.0.1:3000'));
