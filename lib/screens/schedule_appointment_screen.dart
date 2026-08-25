import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../services/firebase_service.dart';

class ScheduleAppointmentScreen extends StatefulWidget {
  const ScheduleAppointmentScreen({super.key});

  @override
  State<ScheduleAppointmentScreen> createState() => _ScheduleAppointmentScreenState();
}

class _ScheduleAppointmentScreenState extends State<ScheduleAppointmentScreen> {
  final List<String> _timeOptions = const ['10:00', '11:00', '12:30', '13:00', '16:00'];
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '11:00';
  String _attendanceType = 'Online';
  bool _isLoadingPsychologists = true;
  List<Map<String, dynamic>> _psychologists = [];
  Map<String, dynamic>? _selectedPsychologist;
  Map<String, dynamic>? _routeProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPsychologists();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra ?? ModalRoute.of(context)?.settings.arguments;
    if (extra is Map<String, dynamic> && _routeProfile == null) {
      _routeProfile = extra;
    }
  }

  Future<void> _loadPsychologists() async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final psychologists = await firebaseService.getRegisteredPsychologists();
      if (!mounted) return;

      setState(() {
        _psychologists = psychologists;
        _selectedPsychologist = _resolveInitialSelectedPsychologist();
        _isLoadingPsychologists = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _psychologists = [];
        _selectedPsychologist = _resolveInitialSelectedPsychologist();
        _isLoadingPsychologists = false;
      });
    }
  }

  Map<String, dynamic>? _resolveInitialSelectedPsychologist() {
    final routeProfile = _routeProfile;
    if (routeProfile != null) {
      final routeId = routeProfile['id']?.toString().trim();
      final routeName = routeProfile['name']?.toString().trim().toLowerCase();
      for (final psychologist in _psychologists) {
        final psychologistId = psychologist['id']?.toString().trim();
        final psychologistName = psychologist['name']?.toString().trim().toLowerCase();
        if ((routeId != null && routeId.isNotEmpty && psychologistId == routeId) ||
            (routeName != null && routeName.isNotEmpty && psychologistName == routeName)) {
          return psychologist;
        }
      }
    }

    if (_psychologists.isNotEmpty) {
      return _psychologists.first;
    }

    return routeProfile;
  }

  Map<String, dynamic>? _selectedProfileOrNull() {
    if (_selectedPsychologist != null) return _selectedPsychologist;
    if (_routeProfile != null) return _routeProfile;
    if (_psychologists.isNotEmpty) return _psychologists.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profile = _selectedProfileOrNull();
    final name = profile?['name']?.toString() ?? 'Selecione um psicólogo';
    final specialty = profile?['specialty']?.toString() ?? profile?['personalizedMessage']?.toString() ?? '';
    final modality = profile?['modality']?.toString() ?? '';
    final availability = profile?['availability']?.toString() ?? '';
    final officeAddress = profile?['officeAddress']?.toString() ?? '';
    final rating = (profile?['rating']?.toString() ?? '4.9');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F1F1F)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'MindMatch',
          style: TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E2E2)),
              color: Colors.white,
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite_border, color: Colors.red, size: 16),
                SizedBox(width: 3),
                Text('1', style: TextStyle(fontSize: 11, color: Color(0xFF222222))),
                SizedBox(width: 2),
                Text('dia', style: TextStyle(fontSize: 10, color: Color(0xFF8A8A8A))),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: Color(0xFF56B35D), shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          child: Column(
            children: [
              _sectionCard(
                icon: Icons.psychology,
                title: 'Profissionais cadastrados',
                subtitle: 'Escolha um psicólogo real da aplicação',
                child: _isLoadingPsychologists
                    ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    : _psychologists.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD7D7D7)),
                            ),
                            child: const Text('Nenhum psicólogo cadastrado foi encontrado. Faça o cadastro do profissional para liberar agendamentos.'),
                          )
                        : Column(
                            children: _psychologists.map((psychologist) {
                              final isSelected = _selectedPsychologist?['id']?.toString() == psychologist['id']?.toString();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedPsychologist = psychologist),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFEFF8EF) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isSelected ? const Color(0xFF56B35D) : const Color(0xFFD7D7D7)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE3E3E3)),
                                          child: const Icon(Icons.person, color: Color(0xFF6E6E6E)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                psychologist['name']?.toString() ?? 'Profissional',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF202020)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                [
                                                  if ((psychologist['specialty']?.toString() ?? '').isNotEmpty) psychologist['specialty'].toString(),
                                                  if ((psychologist['modality']?.toString() ?? '').isNotEmpty) psychologist['modality'].toString(),
                                                ].join(' • '),
                                                style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF56B35D)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
              ),
              const SizedBox(height: 12),
              _doctorCard(name: name, rating: rating, specialty: specialty, modality: modality, availability: availability, officeAddress: officeAddress),
              const SizedBox(height: 12),
              _sectionCard(
                icon: Icons.calendar_month_outlined,
                title: 'Datas disponíveis',
                subtitle: 'Selecione uma data de agendamento',
                child: _calendarBox(),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                icon: Icons.schedule,
                title: 'Horários Disponíveis',
                subtitle: 'Selecione o horário ideal pra você!',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _timeOptions
                      .map((time) => _optionPill(
                            label: time,
                            selected: _selectedTime == time,
                            onTap: () => setState(() => _selectedTime = time),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                icon: Icons.apartment_outlined,
                title: 'Preferência de atendimento',
                subtitle: 'Escolha a mais confortável!',
                child: Row(
                  children: [
                    Expanded(
                      child: _optionPill(
                        label: 'Presencial',
                        selected: _attendanceType == 'Presencial',
                        onTap: () => setState(() => _attendanceType = 'Presencial'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _optionPill(
                        label: 'Online',
                        selected: _attendanceType == 'Online',
                        onTap: () => setState(() => _attendanceType = 'Online'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF56B35D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final selectedProfile = _selectedProfileOrNull();
                    if (selectedProfile == null || (selectedProfile['id']?.toString().isEmpty ?? true)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione um psicólogo cadastrado antes de continuar.')),
                      );
                      return;
                    }

                    final appointment = <String, dynamic>{
                      'profile': selectedProfile,
                      'psychologistId': selectedProfile['id']?.toString(),
                      'psychologistName': selectedProfile['name']?.toString(),
                      'psychologistSpecialty': selectedProfile['specialty']?.toString(),
                      'psychologistModality': selectedProfile['modality']?.toString(),
                      'psychologistAvailability': selectedProfile['availability']?.toString(),
                      'date': _selectedDate.toIso8601String(),
                      'time': _selectedTime,
                      'consultation_type': _attendanceType,
                    };
                    try {
                      context.go('/appointmentConfirmation', extra: appointment);
                    } catch (_) {
                      Navigator.pushNamed(context, '/appointmentConfirmation', arguments: appointment);
                    }
                  },
                  child: const Text('Marcar consulta', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doctorCard({
    required String name,
    required String rating,
    required String specialty,
    required String modality,
    required String availability,
    required String officeAddress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7D7D7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE3E3E3)),
            child: const Icon(Icons.person, color: Color(0xFF6E6E6E)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 30 / 2, fontWeight: FontWeight.w700, color: Color(0xFF202020)),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFF717171), size: 15),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(color: Color(0xFF505050), fontSize: 13)),
                  ],
                )
                ,
                if (specialty.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(specialty, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF505050), fontSize: 12)),
                ],
                if (modality.isNotEmpty || availability.isNotEmpty || officeAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (modality.isNotEmpty) modality,
                      if (availability.isNotEmpty) availability,
                      if (officeAddress.isNotEmpty) officeAddress,
                    ].join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 28, color: Color(0xFF1E1E1E)),
        ],
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7D7D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF56B35D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF56B35D), size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF202020), fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _calendarBox() {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday % 7;
    final monthNames = [
      '',
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    final cells = <Widget>[];
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isSelected =
          date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
      cells.add(
        InkWell(
          onTap: () => setState(() => _selectedDate = date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: isSelected
                ? const BoxDecoration(color: Color(0xFF56B35D), shape: BoxShape.circle)
                : null,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF5F9462),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF56B35D)),
      ),
      child: Column(
        children: [
          Text(
            monthNames[month],
            style: const TextStyle(color: Color(0xFF4F9254), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekLabel('dom.'),
              _WeekLabel('seg.'),
              _WeekLabel('ter.'),
              _WeekLabel('qua.'),
              _WeekLabel('qui.'),
              _WeekLabel('sex.'),
              _WeekLabel('sáb.'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _optionPill({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF56B35D) : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF56B35D) : const Color(0xFFD6D6D6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF1D1D1D),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  final String text;
  const _WeekLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF5F9462),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
