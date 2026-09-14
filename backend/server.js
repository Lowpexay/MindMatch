import express from 'express';
import { chromium } from 'playwright';
import crypto from 'node:crypto';
import fs from 'node:fs';
import admin from 'firebase-admin';

const app = express();
app.use(express.json());

const telegramToken = process.env.TELEGRAM_BOT_TOKEN?.trim();
const telegramUsername = process.env.TELEGRAM_BOT_USERNAME?.replace(/^@/, '').trim();
const publicBackendUrl = process.env.PUBLIC_BACKEND_URL?.replace(/\/$/, '');
const telegramWebhookSecret = process.env.TELEGRAM_WEBHOOK_SECRET?.trim();

let firestore = null;
try {
  const firebaseServiceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON
    ?? (process.env.FIREBASE_SERVICE_ACCOUNT_PATH
      ? fs.readFileSync(process.env.FIREBASE_SERVICE_ACCOUNT_PATH, 'utf8')
      : null);
  if (firebaseServiceAccountJson) {
    const serviceAccount = JSON.parse(firebaseServiceAccountJson);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    firestore = admin.firestore();
    console.log('[Firebase] Admin SDK inicializado');
  }
} catch (error) {
  console.error('[Firebase] não foi possível carregar a credencial:', error.message);
}

const requireFirebase = () => {
  if (!firestore) throw new Error('Firebase Admin não configurado no backend.');
  return firestore;
};

const requireTelegram = () => {
  if (!telegramToken) throw new Error('TELEGRAM_BOT_TOKEN não configurado.');
  return telegramToken;
};

async function verifyFirebaseUser(req) {
  const header = req.headers.authorization ?? '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    const error = new Error('Token Firebase ausente.');
    error.status = 401;
    throw error;
  }
  return admin.auth().verifyIdToken(match[1]);
}

async function telegramApi(method, payload) {
  const token = requireTelegram();
  const response = await fetch(`https://api.telegram.org/bot${token}/${method}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const result = await response.json();
  if (!response.ok || !result.ok) {
    throw new Error(`Telegram ${method} falhou: ${result.description ?? response.status}`);
  }
  return result.result;
}

async function sendTelegramMessage(chatId, text) {
  return telegramApi('sendMessage', { chat_id: chatId, text });
}

function consultationDateTime(date, hour) {
  const parsedDate = new Date(Number(date));
  const match = String(hour ?? '').match(/^(\d{1,2}):(\d{2})/);
  if (Number.isNaN(parsedDate.getTime()) || !match) return null;
  parsedDate.setHours(Number(match[1]), Number(match[2]), 0, 0);
  return parsedDate;
}

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

app.post('/telegram/link-token', async (req, res) => {
  try {
    const user = await verifyFirebaseUser(req);
    const db = requireFirebase();
    if (!telegramUsername) throw new Error('TELEGRAM_BOT_USERNAME não configurado.');

    const token = crypto.randomBytes(24).toString('base64url');
    await db.collection('telegramLinkTokens').doc(token).set({
      uid: user.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: Date.now() + 10 * 60 * 1000,
      used: false,
    });

    res.json({ url: `https://t.me/${telegramUsername}?start=${token}` });
  } catch (error) {
    res.status(error.status ?? 500).json({ error: error.message });
  }
});

app.get('/telegram/status', async (req, res) => {
  try {
    const user = await verifyFirebaseUser(req);
    const snapshot = await requireFirebase().collection('users').doc(user.uid).get();
    const data = snapshot.data() ?? {};
    res.json({
      connected: Boolean(data.telegramChatId),
      notificationsEnabled: data.telegramNotificationsEnabled !== false,
    });
  } catch (error) {
    res.status(error.status ?? 500).json({ error: error.message });
  }
});

app.post('/telegram/disconnect', async (req, res) => {
  try {
    const user = await verifyFirebaseUser(req);
    await requireFirebase().collection('users').doc(user.uid).set({
      telegramChatId: admin.firestore.FieldValue.delete(),
      telegramNotificationsEnabled: false,
      telegramDisconnectedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    res.json({ ok: true });
  } catch (error) {
    res.status(error.status ?? 500).json({ error: error.message });
  }
});

app.post('/telegram/consultation-created', async (req, res) => {
  try {
    const user = await verifyFirebaseUser(req);
    const { consultationId, idPatient, idPsychologist, patientName, date, hour, modality } = req.body ?? {};
    if (!consultationId || !idPatient || !idPsychologist || user.uid !== idPatient) {
      return res.status(400).json({ error: 'Dados de consulta inválidos.' });
    }

    const db = requireFirebase();
    const dateText = date ? new Date(Number(date)).toLocaleDateString('pt-BR') : 'data não informada';
    const message = `Consulta confirmada no MindMatch\n\nPaciente: ${patientName ?? 'Paciente'}\nData: ${dateText}\nHorário: ${hour ?? 'não informado'}\nModalidade: ${modality ?? 'não informada'}`;
    const recipients = [
      { uid: idPsychologist, field: 'telegramPsychologistNotifiedAt' },
      { uid: idPatient, field: 'telegramPatientNotifiedAt' },
    ];
    const sentTo = [];
    const update = {};
    for (const recipient of recipients) {
      const recipientSnapshot = await db.collection('users').doc(recipient.uid).get();
      const recipientData = recipientSnapshot.data() ?? {};
      if (!recipientData.telegramChatId || recipientData.telegramNotificationsEnabled === false) continue;
      await sendTelegramMessage(String(recipientData.telegramChatId), message);
      update[recipient.field] = admin.firestore.FieldValue.serverTimestamp();
      sentTo.push(recipient.uid);
    }
    if (Object.keys(update).length) {
      await db.collection('consultations').doc(String(consultationId)).set(update, { merge: true });
    }
    res.json({ sent: sentTo.length > 0, sentTo });
  } catch (error) {
    res.status(error.status ?? 500).json({ error: error.message });
  }
});

async function sendAppointmentReminders() {
  if (!firestore || !telegramToken) return;
  try {
    const snapshot = await firestore.collection('consultations')
      .where('status', '==', 'SCHEDULED')
      .limit(100)
      .get();
    const now = Date.now();
    for (const document of snapshot.docs) {
      const consultation = document.data();
      if (consultation.telegramPatientReminderSentAt) continue;
      const appointmentAt = consultationDateTime(consultation.date, consultation.hour);
      if (!appointmentAt) continue;
      const remaining = appointmentAt.getTime() - now;
      // One-hour window around the 24-hour mark, so a restart does not lose it.
      if (remaining < 23 * 60 * 60 * 1000 || remaining > 24 * 60 * 60 * 1000) continue;

      const patientSnapshot = await firestore.collection('users').doc(String(consultation.idPatient)).get();
      const patient = patientSnapshot.data() ?? {};
      if (!patient.telegramChatId || patient.telegramNotificationsEnabled === false) continue;

      await sendTelegramMessage(String(patient.telegramChatId),
        `Lembrete de consulta\n\nSua consulta está marcada para amanhã, ${appointmentAt.toLocaleDateString('pt-BR')} às ${consultation.hour}.\n\nModalidade: ${consultation.modality ?? 'não informada'}`);
      await document.ref.set({
        telegramPatientReminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  } catch (error) {
    console.error('[Telegram] erro ao verificar lembretes:', error.message);
  }
}

app.post('/telegram/webhook', async (req, res) => {
  // Telegram retries webhook deliveries; always acknowledge quickly.
  res.sendStatus(200);
  if (telegramWebhookSecret && req.headers['x-telegram-bot-api-secret-token'] !== telegramWebhookSecret) return;
  try {
    const message = req.body?.message;
    const chatId = message?.chat?.id;
    const text = message?.text ?? '';
    if (!chatId || !text.startsWith('/start')) return;

    const token = text.replace(/^\/start\s*/, '').trim();
    if (!token) {
      await sendTelegramMessage(chatId, 'Abra o botão “Conectar Telegram” dentro do MindMatch para vincular sua conta.');
      return;
    }

    const db = requireFirebase();
    const tokenRef = db.collection('telegramLinkTokens').doc(token);
    const tokenSnapshot = await tokenRef.get();
    const tokenData = tokenSnapshot.data();
    if (!tokenSnapshot.exists || !tokenData || tokenData.used || tokenData.expiresAt < Date.now()) {
      await sendTelegramMessage(chatId, 'Esse link expirou. Gere um novo link no MindMatch.');
      return;
    }

    await db.collection('users').doc(tokenData.uid).set({
      telegramChatId: String(chatId),
      telegramUsername: message.from?.username ?? null,
      telegramNotificationsEnabled: true,
      telegramConnectedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await tokenRef.update({ used: true, usedAt: admin.firestore.FieldValue.serverTimestamp() });
    await sendTelegramMessage(chatId, 'Telegram conectado ao MindMatch com sucesso. Você receberá os lembretes das suas consultas por aqui.');
  } catch (error) {
    console.error('[Telegram] erro no webhook:', error.message);
  }
});

async function configureTelegramWebhook() {
  if (!telegramToken || !publicBackendUrl) return;
  try {
    await telegramApi('setWebhook', {
      url: `${publicBackendUrl}/telegram/webhook`,
      ...(telegramWebhookSecret ? { secret_token: telegramWebhookSecret } : {}),
      allowed_updates: ['message'],
    });
    console.log(`[Telegram] webhook configurado em ${publicBackendUrl}/telegram/webhook`);
  } catch (error) {
    console.error('[Telegram] não foi possível configurar o webhook:', error.message);
  }
}

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

const port = Number(process.env.PORT ?? 3000);
app.listen(port, '0.0.0.0', async () => {
  console.log(`Backend MindMatch em http://127.0.0.1:${port}`);
  await configureTelegramWebhook();
  await sendAppointmentReminders();
  setInterval(sendAppointmentReminders, 60 * 1000);
});
