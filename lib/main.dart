import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = StudyModel();
  await model.load();
  runApp(StudyBuddy(model: model));
}

class StudyBuddy extends StatelessWidget {
  const StudyBuddy({super.key, required this.model});
  final StudyModel model;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'StudyBuddy',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4f46e5)),
      scaffoldBackgroundColor: const Color(0xfff7f8fc),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
    ),
    home: Root(model: model),
  );
}

class TaskData {
  TaskData(this.id, this.title, this.course, this.due, this.priority,
      {this.notes = '', this.done = false});
  final String id;
  String title, course, priority, notes;
  DateTime due;
  bool done;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'course': course, 'due': due.toIso8601String(),
    'priority': priority, 'notes': notes, 'done': done,
  };

  factory TaskData.fromJson(Map<String, dynamic> j) => TaskData(
    j['id'], j['title'], j['course'], DateTime.parse(j['due']), j['priority'],
    notes: j['notes'] ?? '', done: j['done'] ?? false,
  );
}

class GroupData {
  GroupData(this.id, this.name, this.course);
  final String id;
  String name, course;
  final List<Map<String, String>> messages = [];
  final List<Map<String, String>> notes = [];

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'course': course,
    'messages': messages, 'notes': notes,
  };

  factory GroupData.fromJson(Map<String, dynamic> j) {
    final g = GroupData(j['id'], j['name'], j['course']);
    for (final value in j['messages'] ?? []) {
      g.messages.add(Map<String, String>.from(value));
    }
    for (final value in j['notes'] ?? []) {
      g.notes.add(Map<String, String>.from(value));
    }
    return g;
  }
}

class StudyModel extends ChangeNotifier {
  final tasks = <TaskData>[];
  final groups = <GroupData>[];
  bool loggedIn = false;
  String name = 'Fahim';
  String email = '';

  int get complete => tasks.where((t) => t.done).length;
  int get pending => tasks.where((t) => !t.done).length;
  double get rate => tasks.isEmpty ? 0 : complete / tasks.length;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    loggedIn = p.getBool('login') ?? false;
    name = p.getString('name') ?? 'Fahim';
    email = p.getString('email') ?? '';
    final rawTasks = p.getString('tasks');
    if (rawTasks == null) {
      final n = DateTime.now();
      tasks.addAll([
        TaskData('1', 'Complete mobile application report', 'ICT725',
          DateTime(n.year, n.month, n.day + 3), 'High',
          notes: 'Add screenshots and the GitHub link.'),
        TaskData('2', 'Review usability feedback', 'ICT725',
          DateTime(n.year, n.month, n.day + 6), 'Medium'),
        TaskData('3', 'Prepare presentation slides', 'ICT725',
          DateTime(n.year, n.month, n.day + 10), 'Low', done: true),
      ]);
    } else {
      for (final value in jsonDecode(rawTasks)) {
        tasks.add(TaskData.fromJson(Map<String, dynamic>.from(value)));
      }
    }
    final rawGroups = p.getString('groups');
    if (rawGroups == null) {
      final g = GroupData('1', 'Mobile App Study Team', 'ICT725');
      g.messages.addAll([
        {'author': 'Aisha', 'text': 'Can we review the prototype after class?', 'time': '10:15'},
        {'author': 'You', 'text': 'Yes, I will share the updated task flow.', 'time': '10:18'},
      ]);
      g.notes.add({'title': 'Presentation checklist',
        'content': 'Demo login, create a task, complete it, then show progress.',
        'author': 'You'});
      groups.add(g);
    } else {
      for (final value in jsonDecode(rawGroups)) {
        groups.add(GroupData.fromJson(Map<String, dynamic>.from(value)));
      }
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('login', loggedIn);
    await p.setString('name', name);
    await p.setString('email', email);
    await p.setString('tasks', jsonEncode(tasks.map((e) => e.toJson()).toList()));
    await p.setString('groups', jsonEncode(groups.map((e) => e.toJson()).toList()));
  }

  Future<void> signIn(String newEmail, String? newName) async {
    loggedIn = true;
    email = newEmail.trim();
    if (newName != null && newName.trim().isNotEmpty) name = newName.trim();
    await save();
    notifyListeners();
  }

  Future<void> signOut() async { loggedIn = false; await save(); notifyListeners(); }
  Future<void> addTask(TaskData t) async { tasks.add(t); await save(); notifyListeners(); }
  Future<void> updateTask() async { await save(); notifyListeners(); }
  Future<void> toggle(TaskData t) async { t.done = !t.done; await save(); notifyListeners(); }
  Future<void> remove(TaskData t) async { tasks.remove(t); await save(); notifyListeners(); }
  Future<void> addGroup(String n, String c) async {
    groups.add(GroupData(DateTime.now().microsecondsSinceEpoch.toString(), n, c));
    await save(); notifyListeners();
  }
  Future<void> send(GroupData g, String text) async {
    final t = TimeOfDay.now();
    g.messages.add({'author': 'You', 'text': text,
      'time': t.hour.toString().padLeft(2, '0') + ':' + t.minute.toString().padLeft(2, '0')});
    await save(); notifyListeners();
  }
  Future<void> addNote(GroupData g, String title, String body) async {
    g.notes.add({'title': title, 'content': body, 'author': 'You'});
    await save(); notifyListeners();
  }
}

class Root extends StatefulWidget {
  const Root({super.key, required this.model});
  final StudyModel model;
  @override State<Root> createState() => _RootState();
}
class _RootState extends State<Root> {
  @override void initState() { super.initState(); widget.model.addListener(refresh); }
  @override void dispose() { widget.model.removeListener(refresh); super.dispose(); }
  void refresh() => setState(() {});
  @override Widget build(BuildContext context) =>
    widget.model.loggedIn ? Shell(model: widget.model) : Login(model: widget.model);
}

class Login extends StatefulWidget {
  const Login({super.key, required this.model});
  final StudyModel model;
  @override State<Login> createState() => _LoginState();
}
class _LoginState extends State<Login> {
  final key = GlobalKey<FormState>();
  final email = TextEditingController(text: 'student@studybuddy.app');
  final password = TextEditingController(text: 'study123');
  final name = TextEditingController();
  bool register = false, hidden = true;

  @override void dispose() { email.dispose(); password.dispose(); name.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Card(child: Padding(padding: const EdgeInsets.all(28),
          child: Form(key: key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const CircleAvatar(radius: 34, child: Icon(Icons.school_rounded, size: 38)),
            const SizedBox(height: 18),
            Text('StudyBuddy', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            Text(register ? 'Create your student workspace' : 'Organise. Collaborate. Succeed.',
              textAlign: TextAlign.center),
            const SizedBox(height: 26),
            if (register) ...[
              TextFormField(controller: name, decoration: const InputDecoration(
                labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                validator: requiredText),
              const SizedBox(height: 12),
            ],
            TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email'),
            const SizedBox(height: 12),
            TextFormField(controller: password, obscureText: hidden,
              decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden),
                  icon: Icon(hidden ? Icons.visibility : Icons.visibility_off))),
              validator: (v) => v != null && v.length >= 6 ? null : 'Use at least 6 characters'),
            const SizedBox(height: 18),
            FilledButton(onPressed: () {
              if (key.currentState!.validate()) {
                widget.model.signIn(email.text, register ? name.text : null);
              }
            }, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(register ? 'Create account' : 'Sign in')),
            TextButton(onPressed: () => setState(() => register = !register),
              child: Text(register ? 'Already registered? Sign in' : 'Create an account')),
          ]))),
        ),
      ),
    ))),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.model});
  final StudyModel model;
  @override State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int selected = 0;
  final titles = ['Dashboard', 'Tasks', 'Calendar', 'Study Groups', 'Progress'];
  final icons = [Icons.dashboard_outlined, Icons.task_alt_outlined,
    Icons.calendar_month_outlined, Icons.groups_outlined, Icons.insights_outlined];

  @override Widget build(BuildContext context) {
    final pages = [
      Dashboard(model: widget.model, go: (v) => setState(() => selected = v)),
      Tasks(model: widget.model),
      Calendar(model: widget.model),
      Groups(model: widget.model),
      Progress(model: widget.model),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(title: Text(titles[selected], style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Center(child: Text(widget.model.name)),
          PopupMenuButton(itemBuilder: (_) => const [PopupMenuItem(value: 'out', child: Text('Sign out'))],
            onSelected: (_) => widget.model.signOut(),
            icon: CircleAvatar(child: Text(widget.model.name[0].toUpperCase()))),
          const SizedBox(width: 10),
        ]),
      body: Row(children: [
        if (wide) NavigationRail(selectedIndex: selected,
          extended: MediaQuery.sizeOf(context).width >= 1120,
          onDestinationSelected: (v) => setState(() => selected = v),
          destinations: List.generate(titles.length, (i) =>
            NavigationRailDestination(icon: Icon(icons[i]), label: Text(titles[i])))),
        if (wide) const VerticalDivider(width: 1),
        Expanded(child: pages[selected]),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: selected,
        onDestinationSelected: (v) => setState(() => selected = v),
        destinations: List.generate(titles.length, (i) =>
          NavigationDestination(icon: Icon(icons[i]), label: titles[i]))),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.model, required this.go});
  final StudyModel model;
  final ValueChanged<int> go;

  @override Widget build(BuildContext context) {
    final upcoming = model.tasks.where((t) => !t.done).toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Hello, ' + model.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const Text('Here is your study plan at a glance.'),
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 12, children: [
        Stat('Pending', model.pending.toString(), Icons.pending_actions, Colors.orange),
        Stat('Completed', model.complete.toString(), Icons.task_alt, Colors.green),
        Stat('Groups', model.groups.length.toString(), Icons.groups, Colors.indigo),
        Stat('Progress', (model.rate * 100).round().toString() + '%', Icons.trending_up, Colors.purple),
      ]),
      const SizedBox(height: 22),
      Text('Quick actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, children: [
        ActionChip(avatar: const Icon(Icons.add_task), label: const Text('Manage tasks'), onPressed: () => go(1)),
        ActionChip(avatar: const Icon(Icons.calendar_month), label: const Text('Deadlines'), onPressed: () => go(2)),
        ActionChip(avatar: const Icon(Icons.groups), label: const Text('Study groups'), onPressed: () => go(3)),
      ]),
      const SizedBox(height: 22),
      Row(children: [Expanded(child: Text('Upcoming deadlines',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
        TextButton(onPressed: () => go(1), child: const Text('View all'))]),
      Card(child: upcoming.isEmpty
        ? const Empty(icon: Icons.celebration, title: 'All caught up', text: 'Create a task to plan your coursework.')
        : Column(children: upcoming.take(4).map((t) => TaskRow(task: t, model: model)).toList())),
    ]);
  }
}

class Stat extends StatelessWidget {
  const Stat(this.label, this.value, this.icon, this.color, {super.key});
  final String label, value;
  final IconData icon;
  final Color color;
  @override Widget build(BuildContext context) => SizedBox(width: 205,
    child: Card(child: Padding(padding: const EdgeInsets.all(18),
      child: Row(children: [
        CircleAvatar(backgroundColor: color.withOpacity(.12), foregroundColor: color, child: Icon(icon)),
        const SizedBox(width: 13),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          Text(label),
        ]),
      ]))));
}

class Tasks extends StatefulWidget {
  const Tasks({super.key, required this.model});
  final StudyModel model;
  @override State<Tasks> createState() => _TasksState();
}
class _TasksState extends State<Tasks> {
  String filter = 'All';
  @override Widget build(BuildContext context) {
    final list = widget.model.tasks.where((t) =>
      filter == 'All' || (filter == 'Pending' && !t.done) || (filter == 'Completed' && t.done)).toList()
      ..sort((a, b) => a.due.compareTo(b.due));
    return Scaffold(backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(onPressed: () => editTask(context, widget.model),
        icon: const Icon(Icons.add), label: const Text('New task')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 90), children: [
        SegmentedButton<String>(segments: const [
          ButtonSegment(value: 'All', label: Text('All')),
          ButtonSegment(value: 'Pending', label: Text('Pending')),
          ButtonSegment(value: 'Completed', label: Text('Completed')),
        ], selected: {filter}, onSelectionChanged: (v) => setState(() => filter = v.first)),
        const SizedBox(height: 18),
        Card(child: list.isEmpty
          ? const Empty(icon: Icons.assignment_outlined, title: 'No tasks here', text: 'Create a task or select another filter.')
          : Column(children: list.map((t) => TaskRow(task: t, model: widget.model, editing: true)).toList())),
      ]));
  }
}

class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, required this.model, this.editing = false});
  final TaskData task;
  final StudyModel model;
  final bool editing;

  @override Widget build(BuildContext context) {
    final color = task.priority == 'High' ? Colors.red : task.priority == 'Medium' ? Colors.orange : Colors.blue;
    return ListTile(minVerticalPadding: 12,
      leading: Checkbox(value: task.done, onChanged: (_) => model.toggle(task)),
      title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w700,
        decoration: task.done ? TextDecoration.lineThrough : null)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Wrap(spacing: 6, children: [
        Chip(label: Text(task.course), visualDensity: VisualDensity.compact),
        Chip(avatar: Icon(Icons.flag_outlined, size: 16, color: color),
          label: Text(task.priority), visualDensity: VisualDensity.compact),
        Chip(avatar: const Icon(Icons.event_outlined, size: 16),
          label: Text(dateText(task.due)), visualDensity: VisualDensity.compact),
      ])),
      trailing: editing ? PopupMenuButton<String>(onSelected: (v) {
        if (v == 'edit') editTask(context, model, task: task);
        if (v == 'delete') model.remove(task);
      }, itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ]) : null);
  }
}

Future<void> editTask(BuildContext context, StudyModel model, {TaskData? task}) async {
  final key = GlobalKey<FormState>();
  final title = TextEditingController(text: task?.title ?? '');
  final course = TextEditingController(text: task?.course ?? '');
  final notes = TextEditingController(text: task?.notes ?? '');
  var due = task?.due ?? DateTime.now().add(const Duration(days: 7));
  var priority = task?.priority ?? 'Medium';
  await showDialog(context: context, builder: (dialog) => StatefulBuilder(builder: (context, setLocal) =>
    AlertDialog(title: Text(task == null ? 'Create task' : 'Edit task'),
      content: SizedBox(width: 440, child: Form(key: key, child: SingleChildScrollView(child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: title, validator: requiredText, decoration: const InputDecoration(labelText: 'Task title')),
          const SizedBox(height: 12),
          TextFormField(controller: course, validator: requiredText, decoration: const InputDecoration(labelText: 'Course')),
          const SizedBox(height: 12),
          DropdownButtonFormField(value: priority, decoration: const InputDecoration(labelText: 'Priority'),
            items: ['Low', 'Medium', 'High'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setLocal(() => priority = v!)),
          const SizedBox(height: 12),
          ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Theme.of(context).colorScheme.outline)),
            leading: const Icon(Icons.event), title: const Text('Due date'), subtitle: Text(dateText(due)),
            onTap: () async {
              final value = await showDatePicker(context: context, initialDate: due,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 730)));
              if (value != null) setLocal(() => due = value);
            }),
          const SizedBox(height: 12),
          TextFormField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (optional)')),
        ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!key.currentState!.validate()) return;
          if (task == null) {
            await model.addTask(TaskData(DateTime.now().microsecondsSinceEpoch.toString(),
              title.text.trim(), course.text.trim(), due, priority, notes: notes.text.trim()));
          } else {
            task.title = title.text.trim(); task.course = course.text.trim();
            task.due = due; task.priority = priority; task.notes = notes.text.trim();
            await model.updateTask();
          }
          if (dialog.mounted) Navigator.pop(dialog);
        }, child: const Text('Save')),
      ])));
  title.dispose(); course.dispose(); notes.dispose();
}

class Calendar extends StatelessWidget {
  const Calendar({super.key, required this.model});
  final StudyModel model;
  @override Widget build(BuildContext context) {
    final list = [...model.tasks]..sort((a, b) => a.due.compareTo(b.due));
    final groups = <String, List<TaskData>>{};
    for (final task in list) { groups.putIfAbsent(dateText(task.due), () => []).add(task); }
    return ListView(padding: const EdgeInsets.all(20), children: [
      Card(color: Theme.of(context).colorScheme.primaryContainer,
        child: const ListTile(minVerticalPadding: 18, leading: Icon(Icons.calendar_month, size: 38),
          title: Text('Deadline calendar'), subtitle: Text('Assignments arranged by due date.'))),
      const SizedBox(height: 16),
      if (groups.isEmpty) const Card(child: Empty(icon: Icons.event_busy, title: 'No deadlines', text: 'Create a task to add a deadline.')),
      ...groups.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12),
        child: Card(child: Padding(padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.key, style: const TextStyle(fontWeight: FontWeight.w900)),
            const Divider(),
            ...e.value.map((t) => TaskRow(task: t, model: model)),
          ]))))),
    ]);
  }
}

class Groups extends StatelessWidget {
  const Groups({super.key, required this.model});
  final StudyModel model;

  Future<void> create(BuildContext context) async {
    final key = GlobalKey<FormState>();
    final name = TextEditingController(), course = TextEditingController();
    await showDialog(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Create study group'),
      content: Form(key: key, child: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: name, validator: requiredText, decoration: const InputDecoration(labelText: 'Group name')),
        const SizedBox(height: 12),
        TextFormField(controller: course, validator: requiredText, decoration: const InputDecoration(labelText: 'Course')),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!key.currentState!.validate()) return;
          await model.addGroup(name.text.trim(), course.text.trim());
          if (dialog.mounted) Navigator.pop(dialog);
        }, child: const Text('Create')),
      ]));
    name.dispose(); course.dispose();
  }

  @override Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.transparent,
    floatingActionButton: FloatingActionButton.extended(onPressed: () => create(context),
      icon: const Icon(Icons.group_add), label: const Text('New group')),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 90), children: [
      if (model.groups.isEmpty) const Card(child: Empty(icon: Icons.groups, title: 'No groups', text: 'Create a group to collaborate.')),
      ...model.groups.map((g) => Padding(padding: const EdgeInsets.only(bottom: 12),
        child: Card(child: ListTile(minVerticalPadding: 16,
          leading: CircleAvatar(child: Text(g.name[0].toUpperCase())),
          title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(g.course + ' • ' + g.messages.length.toString() + ' messages • ' + g.notes.length.toString() + ' notes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetail(model: model, group: g))))))),
    ]));
}

class GroupDetail extends StatefulWidget {
  const GroupDetail({super.key, required this.model, required this.group});
  final StudyModel model;
  final GroupData group;
  @override State<GroupDetail> createState() => _GroupDetailState();
}
class _GroupDetailState extends State<GroupDetail> {
  int tab = 0;
  final message = TextEditingController();
  @override void initState() { super.initState(); widget.model.addListener(refresh); }
  @override void dispose() { widget.model.removeListener(refresh); message.dispose(); super.dispose(); }
  void refresh() => setState(() {});

  Future<void> note() async {
    final key = GlobalKey<FormState>();
    final title = TextEditingController(), body = TextEditingController();
    await showDialog(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Share a note'),
      content: Form(key: key, child: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: title, validator: requiredText, decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 12),
        TextFormField(controller: body, validator: requiredText, maxLines: 5, decoration: const InputDecoration(labelText: 'Content')),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (!key.currentState!.validate()) return;
          await widget.model.addNote(widget.group, title.text.trim(), body.text.trim());
          if (dialog.mounted) Navigator.pop(dialog);
        }, child: const Text('Share')),
      ]));
    title.dispose(); body.dispose();
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.group.name)),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: SegmentedButton<int>(segments: const [
        ButtonSegment(value: 0, icon: Icon(Icons.chat_bubble_outline), label: Text('Discussion')),
        ButtonSegment(value: 1, icon: Icon(Icons.note_alt_outlined), label: Text('Notes')),
      ], selected: {tab}, onSelectionChanged: (v) => setState(() => tab = v.first))),
      Expanded(child: tab == 0 ? discussion() : notes()),
    ]),
    floatingActionButton: tab == 1 ? FloatingActionButton.extended(onPressed: note,
      icon: const Icon(Icons.note_add), label: const Text('New note')) : null);

  Widget discussion() => Column(children: [
    Expanded(child: widget.group.messages.isEmpty
      ? const Empty(icon: Icons.forum, title: 'Start the discussion', text: 'Send the first group message.')
      : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.group.messages.length, itemBuilder: (context, i) {
            final m = widget.group.messages[i], mine = m['author'] == 'You';
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(constraints: const BoxConstraints(maxWidth: 520),
                margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
                  borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((m['author'] ?? '') + ' • ' + (m['time'] ?? ''), style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4), Text(m['text'] ?? ''),
                ])));
          })),
    SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
      Expanded(child: TextField(controller: message, decoration: const InputDecoration(hintText: 'Write a message...'),
        onSubmitted: (_) => send())),
      const SizedBox(width: 8),
      IconButton.filled(onPressed: send, tooltip: 'Send', icon: const Icon(Icons.send)),
    ]))),
  ]);

  void send() {
    if (message.text.trim().isEmpty) return;
    widget.model.send(widget.group, message.text.trim());
    message.clear();
  }

  Widget notes() => widget.group.notes.isEmpty
    ? const Empty(icon: Icons.note_alt_outlined, title: 'No shared notes', text: 'Add a note for the group.')
    : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        children: widget.group.notes.map((n) => Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Card(child: Padding(padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 8), Text(n['content'] ?? ''),
              const SizedBox(height: 10), Text('Shared by ' + (n['author'] ?? '')),
            ]))))).toList());
}

class Progress extends StatelessWidget {
  const Progress({super.key, required this.model});
  final StudyModel model;
  @override Widget build(BuildContext context) {
    final courses = <String, List<TaskData>>{};
    for (final t in model.tasks) { courses.putIfAbsent(t.course, () => []).add(t); }
    return ListView(padding: const EdgeInsets.all(20), children: [
      Card(color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((model.rate * 100).round().toString() + '% complete',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: model.rate, minHeight: 12, borderRadius: BorderRadius.circular(20)),
          const SizedBox(height: 8),
          Text(model.complete.toString() + ' of ' + model.tasks.length.toString() + ' tasks completed'),
        ]))),
      const SizedBox(height: 20),
      Text('Course progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      if (courses.isEmpty) const Card(child: Empty(icon: Icons.insights, title: 'No progress data', text: 'Create tasks to track progress.')),
      ...courses.entries.map((e) {
        final done = e.value.where((t) => t.done).length;
        return Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Card(child: Padding(padding: const EdgeInsets.all(18),
            child: Column(children: [
              Row(children: [Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800))),
                Text(done.toString() + '/' + e.value.length.toString())]),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: done / e.value.length, minHeight: 9, borderRadius: BorderRadius.circular(20)),
            ]))));
      }),
    ]);
  }
}

class Empty extends StatelessWidget {
  const Empty({super.key, required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title, text;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(32),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 46, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 10),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      const SizedBox(height: 5), Text(text, textAlign: TextAlign.center),
    ])));
}

String dateText(DateTime d) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return d.day.toString() + ' ' + m[d.month - 1] + ' ' + d.year.toString();
}
String? requiredText(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;
