import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CourtScannerApp());

class CourtScannerApp extends StatelessWidget {
  const CourtScannerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Court OCR Scanner',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff174a75)), useMaterial3: true),
    home: const ScannerHome(),
  );
}

const headers = <String>[
'SR NO','REGISTER NO','RECEIPT DATE','MONTH/YEAR','FIR','US','PS','ORDER','COURT NAME','PESHI DATE','MONTH/YEAR','ARREST YES/NO','DATE OF ARREST','Whether Peshi Happened or not','REMARK','ISSUE DATE','DESIGNATION','NAME','ADDRESS','MOBILE NO. OF PERSON SUMMONED','Posting place','THROUGH SP','MARK TO','STATUS','REASON','Status of get days to Execute','FINAL STATUS ON SUMMON','compliance report sent to court','compliance report format','CURRENT DATE','SUMMON FOR','AREA OF TAMILI','MOBILE NO','CURRENT DATE','RECEIVED DAYS','Summon Branch get days to execute','summon get in days','PARVI KAR NAME','PURPOSE OF SUMMON','Whether Witness Called','reason for not calling','', 'Whether Witness Attend in court','Whether Evidence Recorded or Not','REASON NOT RECORDED EVIDENCE','REQUEST REASON','EVIDENCE TIME','REMARKS','Status of Recording','Delay in receiving Summons','Status of delay','POSTINGS','EXECUTION DAYS','CATAGORY'
];

class ScannerHome extends StatefulWidget {
  const ScannerHome({super.key});
  @override State<ScannerHome> createState() => _ScannerHomeState();
}

class _ScannerHomeState extends State<ScannerHome> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final Map<String, TextEditingController> fields = {};
  String rawText = '';
  String status = 'Scan a document or import your SC.xlsx template.';
  File? imageFile;
  Uint8List? templateBytes;
  String? templateName;
  bool busy = false;
  List<String> recipientOptions = [
    'SHO CITY','SHO BAHIN','EHC SUBHASH CHAND','SPO RAMESH 246',
    'CT RAVI 1497 PWL','EHC KARTAR 118','CT AJAY 99','CT NASEEM KHAN 473',
    'EHC HASAN'
  ];

  final fieldLabels = const [
    'REGISTER NO','RECEIPT DATE','FIR','UNDER SECTION','PS','ORDER','COURT NAME','PESHI DATE',
    'ARREST YES/NO','DATE OF ARREST','Whether Peshi Happened or not','REMARK',
    'ISSUE DATE','DESIGNATION','NAME','ADDRESS','MOBILE NO. OF PERSON SUMMONED',
    'Posting place','THROUGH SP','MARK TO','STATUS','REASON',
    'Status of get days to Execute','FINAL STATUS ON SUMMON',
    'compliance report sent to court','compliance report format','AE PERSON TYPE',
    'AF AREA TYPE','MOBILE NO','PARVI KAR NAME','AM CASE ROLE',
    'Whether Witness Called','reason for not calling','Whether Witness Attend in court',
    'Whether Evidence Recorded or Not','REASON NOT RECORDED EVIDENCE','REQUEST REASON',
    'EVIDENCE TIME','REMARKS','Status of Recording','Delay in receiving Summons',
    'Status of delay','POSTINGS','EXECUTION DAYS','CATAGORY'
  ];

  @override void initState() {
    super.initState();
    _loadRecipients();
    for (final h in fieldLabels) { fields[h] = TextEditingController(); }
    fields['RECEIPT DATE']!.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    fields['ISSUE DATE']!.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    fields['ORDER']!.text = 'NOTICE';
    fields['AE PERSON TYPE']!.text = 'POLICE';
    fields['AF AREA TYPE']!.text = 'WITHIN DISTRICT';
    fields['AM CASE ROLE']!.text = 'WITNESS';
    fields['STATUS']!.text = 'PENDING';
    fields['THROUGH SP']!.text = '';
    fields['STATUS']!.text = 'PENDING';
    fields['Whether Peshi Happened or not']!.text = 'PENDING';
    fields['Whether Witness Called']!.text = 'PENDING';
    fields['Whether Witness Attend in court']!.text = 'PENDING';
    fields['Whether Evidence Recorded or Not']!.text = 'PENDING';
  }

  Future<void> _loadRecipients() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('court_ocr_recipients');
    if (saved != null && mounted) setState(() => recipientOptions = saved);
  }

  Future<void> manageRecipients() async {
    final addController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage MARK TO recipients'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: TextField(controller: addController, decoration: const InputDecoration(hintText: 'Enter recipient name'))),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    final value = addController.text.trim();
                    if (value.isNotEmpty && !recipientOptions.contains(value)) {
                      setDialogState(() => recipientOptions.add(value));
                      addController.clear();
                    }
                  },
                ),
              ]),
              const SizedBox(height: 8),
              Flexible(child: ListView(
                shrinkWrap: true,
                children: recipientOptions.map((name) => ListTile(
                  dense: true,
                  title: Text(name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setDialogState(() => recipientOptions.remove(name)),
                  ),
                )).toList(),
              )),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setStringList('court_ocr_recipients', recipientOptions);
              if (mounted) setState(() {});
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            }, child: const Text('Save options')),
          ],
        ),
      ),
    );
    addController.dispose();
  }

  @override void dispose() {
    _recognizer.close();
    for (final c in fields.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> scan(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 95);
    if (picked == null) return;
    setState(() { busy = true; imageFile = File(picked.path); status = 'Reading document…'; });
    try {
      final result = await _recognizer.processImage(InputImage.fromFilePath(picked.path));
      rawText = result.text;
      mapTextToFields(rawText);
      setState(() { status = 'OCR complete. Check every field before saving.'; });
    } catch (e) {
      setState(() { status = 'OCR failed: $e'; });
    } finally { setState(() { busy = false; }); }
  }

  String? matchAfter(List<String> lines, List<RegExp> patterns) {
    for (int i=0; i<lines.length; i++) {
      final line=lines[i];
      if (patterns.any((p)=>p.hasMatch(line))) {
        final after = line.split(RegExp(r'[:/]')).skip(1).join(':').trim();
        if (after.length > 2) return after;
        if (i+1<lines.length && lines[i+1].trim().length>2) return lines[i+1].trim();
      }
    }
    return null;
  }

  void setIfFound(String key, String? value) {
    if (value != null && fields.containsKey(key)) fields[key]!.text = value.trim();
  }

  void mapTextToFields(String text) {
    // Prevent values from a previous scan leaking into the next record.
    for (final controller in fields.values) { controller.clear(); }
    fields['RECEIPT DATE']!.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    fields['ISSUE DATE']!.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    fields['ORDER']!.text = 'NOTICE';
    fields['AE PERSON TYPE']!.text = 'POLICE';
    fields['AF AREA TYPE']!.text = 'WITHIN DISTRICT';
    fields['AM CASE ROLE']!.text = 'WITNESS';
    fields['STATUS']!.text = 'PENDING';
    fields['Whether Peshi Happened or not']!.text = 'PENDING';
    fields['Whether Witness Called']!.text = 'PENDING';
    fields['Whether Witness Attend in court']!.text = 'PENDING';
    fields['Whether Evidence Recorded or Not']!.text = 'PENDING';
    final lines = text.split('\n').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
    final upper = text.toUpperCase();
    String normalizeDate(String s) {
      final p=s.replaceAll('.', '/').replaceAll('-', '/').split('/');
      if(p.length!=3) return s;
      return '${p[0].padLeft(2,'0')}/${p[1].padLeft(2,'0')}/${p[2]}';
    }
    String? dateAfter(String label) {
      final idx=upper.indexOf(label);
      if(idx<0) return null;
      final tail=text.substring(idx);
      final m=RegExp(r'\b\d{1,2}[-/\.]\d{1,2}[-/\.]\d{4}\b').firstMatch(tail);
      return m==null ? null : normalizeDate(m.group(0)!);
    }
    String? dateNearEnd() {
      final matches=RegExp(r'\b\d{1,2}[-/\.]\d{1,2}[-/\.]\d{4}\b').allMatches(text).toList();
      return matches.isEmpty ? null : normalizeDate(matches.last.group(0)!);
    }
    final sectionMatch = RegExp(r'(?:UNDER\s+SECTION[S]?|U/S|SECTIONS?)\s*[:.]?\s*([0-9A-Z ,./() -]{1,45})', caseSensitive:false).firstMatch(text);
    if (sectionMatch != null) {
      setIfFound('UNDER SECTION', sectionMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim());
    }
    // Case-law sections: capture the text immediately following the police station/FIR line.
    final psLine = lines.firstWhere((l)=>RegExp(r'POLICE STATION\s*/?\s*FIR|POLICE STATION/FIR NO',caseSensitive:false).hasMatch(l),orElse:()=> '');
    if(psLine.isNotEmpty) {
      final after=psLine.replaceFirst(RegExp(r'.*?POLICE STATION\s*/?\s*FIR(?:\s*NO\.?)?\s*',caseSensitive:false),'').trim();
      final parts=after.split('/');
      if(parts.length>=2) {
        setIfFound('PS',parts.first.trim());
        setIfFound('FIR',parts.skip(1).take(2).join('/').replaceAll(RegExp(r'\s+'),'').trim());
      } else {
        setIfFound('PS',after);
      }
    }
    // A court case reference often appears before the case title; keep it in FIR only if no police/FIR line was found.
    if((fields['FIR']?.text.trim().isEmpty ?? true)) {
      final m=RegExp(r'\b[A-Z]{2,5}\s*/\s*\d+\s*/\s*\d{4}\b').firstMatch(text);
      if(m!=null) setIfFound('FIR',m.group(0)!.replaceAll(' ',''));
    }
    if(upper.contains('NON-BAILABLE')) setIfFound('ORDER','NON-BAILABLE WARRANT');
    else if(upper.contains('BAILABLE WARRANT')) setIfFound('ORDER','BAILABLE WARRANT');
    else if(upper.contains('PROCLAMATION')) setIfFound('ORDER','PROCLAMATION');
    else if(upper.contains('SUMMON TO WITNESS') || upper.contains('SUMMONS TO WITNESS')) setIfFound('ORDER','SUMMONS TO WITNESS');
    else if(upper.contains('SUMMON')) setIfFound('ORDER','SUMMONS');
    setIfFound('PESHI DATE',dateAfter('NEXT DATE'));
    setIfFound('ISSUE DATE',dateAfter('DATED, THIS DAY OF') ?? dateAfter('GIVEN UNDER MY HAND') ?? dateNearEnd());
    final courtLine = lines.firstWhere((l)=>RegExp(r'IN THE COURT OF',caseSensitive:false).hasMatch(l),orElse:()=> '');
    if (courtLine.isNotEmpty) {
      var judge = courtLine.replaceFirst(RegExp(r'.*?IN THE COURT OF',caseSensitive:false), '').trim();
      judge = judge.replaceFirst(RegExp(r'^(SHRI|SH\.?|SMT\.?|MS\.?|MRS\.?|MR\.?)\s*',caseSensitive:false), '').trim();
      if (judge.isEmpty) {
        final idx = lines.indexOf(courtLine);
        if (idx + 1 < lines.length) judge = lines[idx + 1].trim();
      }
      judge = judge.replaceAll(RegExp(r'\s+'), ' ').replaceAll(',', '').trim();
      if (judge.isNotEmpty) {
        final upperJudge = judge.toUpperCase();
        if (upperJudge.contains('ADDITIONAL DISTRICT') || upperJudge.contains('ADJ')) {
          setIfFound('COURT NAME', 'ADJ ' + judge.replaceFirst(RegExp(r'^(ADJ|ADDITIONAL DISTRICT AND SESSIONS JUDGE)\s*',caseSensitive:false),'').toUpperCase());
        } else {
          setIfFound('COURT NAME', 'JMIC ' + judge.toUpperCase());
        }
      }
    }
    final mobileMatches=RegExp(r'\b[6-9]\d{9}\b').allMatches(text).toList();
    if(mobileMatches.isNotEmpty) setIfFound('MOBILE NO. OF PERSON SUMMONED',mobileMatches.last.group(0));
    // Name usually follows "Whereas"; remove common legal introductory wording and keep the first person phrase.
    final where = RegExp(r'Whereas\s+(.{3,100}?)(?:\s+has been duly served|\s+has been served|\s+has failed|\s+resident of)',caseSensitive:false,dotAll:true).firstMatch(text);
    if(where!=null) {
      var person=where.group(1)!.replaceAll(RegExp(r'\s+'),' ').trim();
      setIfFound('NAME',person);
    } else {
      final nameLine=lines.firstWhere((l)=>RegExp(r'^Name\s*:',caseSensitive:false).hasMatch(l),orElse:()=> '');
      if(nameLine.isNotEmpty) setIfFound('NAME',nameLine.split(':').skip(1).join(':').trim());
    }
    // Address is intentionally left editable because addresses can span multiple lines.
    setIfFound('REMARK','OCR extracted — verify all fields against original');
    setState(() {});
  }

  Future<void> importTemplate() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true);
    if (res == null || res.files.single.bytes == null) return;
    setState(() { templateBytes = res.files.single.bytes!; templateName=res.files.single.name; status='Template loaded: $templateName'; });
  }

  String monthYear(String date) {
    try { return DateFormat('MMMyyyy').format(DateFormat('dd/MM/yyyy').parseStrict(date)); } catch (_) { return ''; }
  }

  Future<void> saveExcel() async {
    if (templateBytes == null) {
      setState(() { status='Import your existing SC.xlsx first. No file has been saved.'; });
      return;
    }
    setState(() { busy=true; status='Preparing a new row for review/export…'; });
    try {
      final excel = Excel.decodeBytes(templateBytes!);
      final sheet = excel['Visible Data'];
      // The source workbook has duplicate MONTH/YEAR and CURRENT DATE headers.
      // Use the exact SC.xlsx column positions (1-based labels converted to zero-based indices).
      int lastDataRow = 0;
      for (int r = 1; r < sheet.maxRows; r++) {
        final existing = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value;
        if (existing != null && existing.toString().trim().isNotEmpty) lastDataRow = r;
      }
      final row = lastDataRow + 1;
      final v = <String,String>{for(final e in fields.entries)e.key:e.value.text.trim()};
      final receipt = v['RECEIPT DATE'] ?? '';
      final peshi = v['PESHI DATE'] ?? '';
      String monthYear(String d) {
        try { return DateFormat('MMMyyyy').format(DateFormat('dd/MM/yyyy').parseStrict(d)); } catch (_) { return ''; }
      }
      final now=DateFormat('dd/MM/yyyy').format(DateTime.now());
      final cells=<int,String>{
        0: (() {
          int count = 0;
          for (int r = 1; r < row; r++) {
            final d = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value?.toString().trim() ?? '';
            if (d == receipt) count++;
          }
          return (count + 1).toString();
        })(), // A daily serial number
        1: (() {
          int count = 0;
          final court = (v['COURT NAME'] ?? '').trim().toUpperCase();
          for (int r = 1; r < row; r++) {
            final existingCourt = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: r)).value?.toString().trim().toUpperCase() ?? '';
            if (court.isNotEmpty && existingCourt == court) count++;
          }
          return (count + 1).toString();
        })(), // B registration counter per court
        2: receipt,          // C RECEIPT DATE
        3: monthYear(receipt),// D MONTH/YEAR
        4: v['FIR'] ?? '',   // E FIR
        5: v['UNDER SECTION'] ?? '',    // F US / sections
        6: v['PS'] ?? '',    // G PS
        7: v['ORDER'] ?? '', // H ORDER
        8: v['COURT NAME'] ?? '', // I COURT NAME
        9: peshi,            // J PESHI DATE
        10: monthYear(peshi),// K MONTH/YEAR
        11: v['ARREST YES/NO'] ?? '', // L
        12: v['DATE OF ARREST'] ?? '',// M
        13: v['Whether Peshi Happened or not'] ?? 'PENDING', // N
        14: v['REMARK'] ?? '', // O
        15: v['ISSUE DATE'] ?? now, // P
        16: v['DESIGNATION'] ?? '', // Q
        17: v['NAME'] ?? '', // R
        18: v['ADDRESS'] ?? '', // S
        19: v['MOBILE NO. OF PERSON SUMMONED'] ?? '', // T
        20: v['Posting place'] ?? '', // U
        21: v['THROUGH SP'] ?? '', // V
        22: v['MARK TO'] ?? '', // W
        23: v['STATUS'] ?? 'PENDING', // X
        24: v['REASON'] ?? '', // Y
        25: v['Status of get days to Execute'] ?? '', // Z
        26: v['FINAL STATUS ON SUMMON'] ?? '', // AA
        27: v['compliance report sent to court'] ?? '', // AB
        28: v['compliance report format'] ?? '', // AC
        29: now, // AD CURRENT DATE
        30: v['AE PERSON TYPE'] ?? 'POLICE', // AE
        31: v['AF AREA TYPE'] ?? 'WITHIN DISTRICT', // AF
        32: v['MOBILE NO'] ?? '', // AG
        33: now, // AH CURRENT DATE
        37: v['PARVI KAR NAME'] ?? '', // AL
        38: v['AM CASE ROLE'] ?? 'WITNESS', // AM
        39: v['Whether Witness Called'] ?? 'PENDING', // AN
        40: v['reason for not calling'] ?? '', // AO
        42: v['Whether Witness Attend in court'] ?? 'PENDING', // AQ
        43: v['Whether Evidence Recorded or Not'] ?? 'PENDING', // AR
        44: v['REASON NOT RECORDED EVIDENCE'] ?? '', // AS
        45: v['REQUEST REASON'] ?? '', // AT
        46: v['EVIDENCE TIME'] ?? '', // AU
        47: v['REMARKS'] ?? '', // AV
        48: v['Status of Recording'] ?? '', // AW
        49: v['Delay in receiving Summons'] ?? '', // AX
        50: v['Status of delay'] ?? '', // AY
        51: v['POSTINGS'] ?? '', // AZ
        52: v['EXECUTION DAYS'] ?? '', // BA
        53: v['CATAGORY'] ?? '', // BB
      };
      for(final entry in cells.entries) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex:entry.key,rowIndex:row)).value =
          entry.value.isEmpty ? const TextCellValue('') : TextCellValue(entry.value);
      }
      final out=excel.encode();
      if(out==null) throw Exception('Could not encode workbook');
      final dir=await getTemporaryDirectory();
      final file=File('${dir.path}/SC_with_new_record_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(out,flush:true);
      setState(() { busy=false; status='New row prepared. Check the editable fields above; the Excel copy is ready to share/export.'; });
      await Share.shareXFiles([XFile(file.path)], text:'Court OCR record — verify before official use');
    } catch(e) {
      setState(() { status='Export error: $e'; });
    } finally { setState(() { busy=false; }); }
  }

  Widget input(String label) {
    const choices = <String, List<String>>{
      'ORDER': ['BAILABLE WARRANT','NON-BAILABLE WARRANT','NOTICE','SUMMONS','SUMMONS TO WITNESS','WARRANT OF ARREST','PROCLAMATION'],
      'AE PERSON TYPE': ['PRIVATE PERSON','POLICE'],
      'AF AREA TYPE': ['WITHIN DISTRICT','OUT OF DISTRICT','OUT OF STATE'],
      'AM CASE ROLE': ['WITNESS','ACCUSED'],
      'ARREST YES/NO': ['YES','NO'],
      'Whether Peshi Happened or not': ['YES','NO','PENDING'],
    };
    if (label == 'MARK TO') {
      final recipients = [...recipientOptions, 'OTHER / ENTER MANUALLY'];
      return Padding(
        padding: const EdgeInsets.only(bottom:10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<String>(
            value: recipients.contains(fields[label]!.text) ? fields[label]!.text : 'OTHER / ENTER MANUALLY',
            decoration: const InputDecoration(labelText:'MARK TO — choose a saved recipient', border:OutlineInputBorder(), isDense:true),
            items: recipients.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
            onChanged:(v) {
              if (v != null && v != 'OTHER / ENTER MANUALLY') fields[label]!.text = v;
              if (v == 'OTHER / ENTER MANUALLY') fields[label]!.clear();
              setState(() {});
            },
          ),
          const SizedBox(height:8),
          TextField(controller: fields[label], decoration: const InputDecoration(labelText:'MARK TO — edit or enter a name manually', border:OutlineInputBorder(), isDense:true), textCapitalization:TextCapitalization.characters),
        ]),
      );
    }
    if (choices.containsKey(label)) {
      final options = choices[label]!;
      final controller = fields[label]!;
      final selected = options.contains(controller.text) ? controller.text : options.first;
      return Padding(
        padding: const EdgeInsets.only(bottom:10),
        child: DropdownButtonFormField<String>(
          value: selected,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
          items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) { if (v != null) controller.text = v; },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom:10),
      child: TextField(controller: fields[label], decoration: InputDecoration(labelText:label, border:const OutlineInputBorder(), isDense:true), textCapitalization: TextCapitalization.characters),
    );
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Court OCR Scanner'), actions:[IconButton(onPressed:manageRecipients, icon:const Icon(Icons.settings), tooltip:'Manage recipients'), IconButton(onPressed:importTemplate, icon:const Icon(Icons.file_open), tooltip:'Import SC.xlsx')]),
      body: ListView(padding:const EdgeInsets.all(16), children:[
        Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('1. Scan document',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:10),
          Wrap(spacing:8,runSpacing:8,children:[
            FilledButton.icon(onPressed:busy?null:()=>scan(ImageSource.camera),icon:const Icon(Icons.camera_alt),label:const Text('Camera scan')),
            OutlinedButton.icon(onPressed:busy?null:()=>scan(ImageSource.gallery),icon:const Icon(Icons.photo_library),label:const Text('Choose photo')),
            OutlinedButton.icon(onPressed:busy?null:importTemplate,icon:const Icon(Icons.table_view),label:const Text('Import SC.xlsx')),
          ]),
          if(imageFile!=null) Padding(padding:const EdgeInsets.only(top:12),child:ClipRRect(borderRadius:BorderRadius.circular(8),child:Image.file(imageFile!,height:180,fit:BoxFit.contain))),
        ]))),
        Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('2. Review and correct before saving',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:6),
          const Text('OCR is only a suggestion. Confirm all dates, FIR/case numbers, names, police station and action fields.'),
          const SizedBox(height:12),
          ...fieldLabels.map(input),
          ExpansionTile(title:const Text('View raw OCR text'),children:[Padding(padding:const EdgeInsets.all(12),child:SelectableText(rawText.isEmpty?'No OCR text yet.':rawText))]),
        ]))),
        Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('3. Save / export',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          const SizedBox(height:8),
          Text(templateName==null?'No Excel template imported. Import SC.xlsx to preserve its columns.':'Template: $templateName'),
          const SizedBox(height:8),
          FilledButton.icon(onPressed:busy?null:saveExcel,icon:const Icon(Icons.save_alt),label:const Text('Prepare Excel and export')),
          const SizedBox(height:8),
          Text(status),
          if(busy) const Padding(padding:EdgeInsets.only(top:8),child:LinearProgressIndicator()),
        ]))),
        const Padding(padding:EdgeInsets.all(8),child:Text('Privacy: OCR runs on-device. Exported spreadsheets may contain sensitive personal and court data; share only with authorized recipients.',style:TextStyle(fontSize:12))),
      ]),
    );
  }
}
