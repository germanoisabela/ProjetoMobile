import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../home/domain/repositories/project_repository.dart';
import '../../../rules/presentation/pages/site_form_page.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/point_2d.dart';
import '../../domain/entities/wall.dart';
import '../widgets/plan_painter.dart';
import '../widgets/plan_viewport.dart';

enum _EditorTool { select, measure, draw }

class PlanEditorPage extends StatefulWidget {
  final Plan plan;
  final ProjectRepository? projectRepository;

  const PlanEditorPage({
    super.key,
    required this.plan,
    this.projectRepository,
  });

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  static const double _vertexTouchRadius = 24;
  static const double _wallTouchDistance = 20;
  static const double _tapSlop = 8;
  static const double _snapStepM = 0.05;
  static const int _maxUndo = 50;

  late Plan _plan;
  final List<Plan> _undoStack = [];
  Plan? _planBeforeDrag;
  _EditorTool _tool = _EditorTool.select;
  PlanViewport? _viewport;
  Size? _canvasSize;
  int? _selectedWall;
  int? _draggedVertex;
  Point2D? _measureStart;
  Point2D? _measureEnd;
  int? _activePointer;
  Offset _downPosition = Offset.zero;
  bool _moved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
  }

  @override
  void didUpdateWidget(covariant PlanEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan != widget.plan) {
      _plan = widget.plan;
      _viewport = null;
      _canvasSize = null;
      _selectedWall = null;
      _draggedVertex = null;
      _undoStack.clear();
      _planBeforeDrag = null;
      _measureStart = null;
      _measureEnd = null;
    }
  }

  void _pushUndo(Plan plan) {
    _undoStack.add(plan);
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _plan = _undoStack.removeLast();
      _selectedWall = null;
      _measureStart = null;
      _measureEnd = null;
    });
  }

  int? _hitVertex(Offset position) {
    final PlanViewport? viewport = _viewport;
    if (viewport == null) return null;

    int? best;
    double bestDistance = _vertexTouchRadius;
    for (int i = 0; i < _plan.vertices.length; i++) {
      final double distance =
          (viewport.toCanvas(_plan.vertices[i]) - position).distance;
      if (distance <= bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    return best;
  }

  int? _hitWall(Offset position) {
    final PlanViewport? viewport = _viewport;
    if (viewport == null) return null;

    int? best;
    double bestDistance = _wallTouchDistance;
    final List<Wall> walls = _plan.walls;
    for (int i = 0; i < walls.length; i++) {
      final double distance = _distanceToSegment(
        position,
        viewport.toCanvas(walls[i].start),
        viewport.toCanvas(walls[i].end),
      );
      if (distance <= bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    return best;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final Offset segment = end - start;
    final double lengthSquared =
        segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) return (point - start).distance;

    final Offset fromStart = point - start;
    final double t =
        (fromStart.dx * segment.dx + fromStart.dy * segment.dy) / lengthSquared;
    final Offset closest = start + segment * t.clamp(0.0, 1.0).toDouble();
    return (point - closest).distance;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointer != null) {
      _moved = true;
      if (_draggedVertex != null) {
        _commitDragToUndo();
        setState(() => _draggedVertex = null);
      }
      return;
    }

    _activePointer = event.pointer;
    _downPosition = event.localPosition;
    _moved = false;

    if (_tool != _EditorTool.measure) {
      final int? vertex = _hitVertex(event.localPosition);
      if (vertex != null) {
        _planBeforeDrag = _plan;
        setState(() => _draggedVertex = vertex);
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;

    if ((event.localPosition - _downPosition).distance > _tapSlop) {
      _moved = true;
    }

    final int? vertex = _draggedVertex;
    final PlanViewport? viewport = _viewport;
    if (!_moved || vertex == null || viewport == null) return;

    final Point2D target =
        viewport.toMeters(event.localPosition).snapTo(_snapStepM);
    setState(() => _plan = _plan.moveVertex(vertex, target));
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;

    final int? vertex = _draggedVertex;
    final bool wasTap = !_moved;
    if (vertex != null && !wasTap) _commitDragToUndo();
    if (wasTap) _planBeforeDrag = null;
    setState(() => _draggedVertex = null);
    if (wasTap) _handleTap(event.localPosition, tappedVertex: vertex);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    if (_draggedVertex != null) _commitDragToUndo();
    setState(() => _draggedVertex = null);
  }

  void _commitDragToUndo() {
    final Plan? before = _planBeforeDrag;
    if (before != null && !identical(before, _plan)) _pushUndo(before);
    _planBeforeDrag = null;
  }

  void _handleTap(Offset position, {int? tappedVertex}) {
    switch (_tool) {
      case _EditorTool.select:
        setState(() => _selectedWall = _hitWall(position));
        return;
      case _EditorTool.measure:
        _onMeasureTap(position);
        return;
      case _EditorTool.draw:
        _onDrawTap(position, tappedVertex);
        return;
    }
  }

  void _onMeasureTap(Offset position) {
    final PlanViewport? viewport = _viewport;
    if (viewport == null) return;

    final int? vertex = _hitVertex(position);
    final Point2D point = vertex == null
        ? viewport.toMeters(position).snapTo(_snapStepM)
        : _plan.vertices[vertex];
    setState(() {
      if (_measureStart == null || _measureEnd != null) {
        _measureStart = point;
        _measureEnd = null;
      } else {
        _measureEnd = point;
      }
    });
  }

  void _clearMeasurement() {
    setState(() {
      _measureStart = null;
      _measureEnd = null;
    });
  }

  void _onDrawTap(Offset position, int? tappedVertex) {
    if (tappedVertex != null) {
      if (_plan.vertices.length <= 3) {
        _showMessage('Uma planta precisa de pelo menos 3 cantos.');
        return;
      }
      _pushUndo(_plan);
      setState(() {
        _plan = _plan.removeVertex(tappedVertex);
        _selectedWall = null;
      });
      return;
    }

    final PlanViewport? viewport = _viewport;
    final int? wallIndex = _hitWall(position);
    if (viewport == null || wallIndex == null) return;

    final Wall wall = _plan.walls[wallIndex];
    if (wall.lengthM < 2 * _snapStepM) {
      _showMessage('Parede curta demais para receber um canto.');
      return;
    }
    final double along = wall.start.distanceTo(
      wall.closestPointTo(viewport.toMeters(position)),
    );
    final double snapped = ((along / _snapStepM).round() * _snapStepM)
        .clamp(_snapStepM, wall.lengthM - _snapStepM)
        .toDouble();

    _pushUndo(_plan);
    setState(() {
      _plan =
          _plan.insertVertexOnWall(wallIndex, wall.pointAtDistance(snapped));
      _selectedWall = null;
    });
  }

  void _selectTool(_EditorTool tool) {
    setState(() {
      _tool = _tool == tool ? _EditorTool.select : tool;
      _selectedWall = null;
      _measureStart = null;
      _measureEnd = null;
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _editSelectedWall() async {
    final int? index = _selectedWall;
    if (index == null) return;

    final double? newLength = await showDialog<double>(
      context: context,
      builder: (_) =>
          _EditLengthDialog(initialValue: _plan.walls[index].lengthM),
    );

    if (newLength == null || !mounted) return;
    _pushUndo(_plan);
    setState(() => _plan = _plan.withWallLength(index, newLength));
  }

  void _restore() {
    if (identical(_plan, widget.plan)) return;
    _pushUndo(_plan);
    setState(() {
      _plan = widget.plan;
      _selectedWall = null;
      _draggedVertex = null;
      _measureStart = null;
      _measureEnd = null;
    });
  }

  /// Abre a análise preliminar usando a planta como está AGORA.
  void _openAnalysis() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SiteFormPage(plan: _plan)),
    );
  }

  Future<void> _saveProject() async {
    final repository = widget.projectRepository;
    if (repository == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final project = await repository.createProject(
        name: _plan.name,
        areaM2: _plan.areaM2,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${project.name} foi salvo nos seus projetos.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o projeto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _plan.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            tooltip: 'Salvar projeto',
            onPressed: _isSaving || widget.projectRepository == null
                ? null
                : _saveProject,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Desfazer',
            onPressed: _undoStack.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Restaurar medidas originais',
            onPressed: _restore,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _buildSummaryCard(),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Size size = constraints.biggest;
                if (_viewport == null || _canvasSize != size) {
                  _canvasSize = size;
                  _viewport = PlanViewport.fit(plan: _plan, canvasSize: size);
                }

                return Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5,
                        boundaryMargin: const EdgeInsets.all(80),
                        panEnabled: _draggedVertex == null,
                        scaleEnabled: _draggedVertex == null,
                        child: SizedBox.expand(
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: _onPointerDown,
                            onPointerMove: _onPointerMove,
                            onPointerUp: _onPointerUp,
                            onPointerCancel: _onPointerCancel,
                            child: CustomPaint(
                              painter: PlanPainter(
                                plan: _plan,
                                viewport: _viewport!,
                                selectedWall: _selectedWall,
                                draggedVertex: _draggedVertex,
                                measureStart: _measureStart,
                                measureEnd: _measureEnd,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: _buildBottomOverlay(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ToolButton(
                icon: Icons.straighten,
                label: 'Medir',
                selected: _tool == _EditorTool.measure,
                onTap: () => _selectTool(_EditorTool.measure),
              ),
              _ToolButton(
                icon: Icons.edit_outlined,
                label: 'Desenhar',
                selected: _tool == _EditorTool.draw,
                onTap: () => _selectTool(_EditorTool.draw),
              ),
              _ToolButton(
                icon: Icons.home_work_outlined,
                label: 'Analisar',
                selected: false,
                onTap: _openAnalysis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Metric(value: '${formatDecimal(_plan.areaM2)} m²', label: 'Área'),
            _Metric(
              value: '${formatDecimal(_plan.perimeterM)} m',
              label: 'Perímetro',
            ),
            _Metric(value: '${_plan.walls.length}', label: 'Paredes'),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    switch (_tool) {
      case _EditorTool.measure:
        if (_measureStart != null && _measureEnd != null) {
          return _buildMeasureCard();
        }
        return _hint(
          _measureStart == null
              ? 'Toque no primeiro ponto da medição'
              : 'Agora toque no segundo ponto',
        );
      case _EditorTool.draw:
        return _hint(
          'Toque numa parede para criar um canto. '
          'Toque num canto para removê-lo.',
        );
      case _EditorTool.select:
        final int? index = _selectedWall;
        if (index == null) {
          return _hint('Toque numa parede ou arraste os cantos');
        }
        return _buildSelectedWallCard(index);
    }
  }

  Widget _hint(String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildSelectedWallCard(int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Parede ${index + 1} • '
                '${formatDecimal(_plan.walls[index].lengthM)} m',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton.tonal(
              onPressed: _editSelectedWall,
              child: const Text('Editar medida'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Limpar seleção',
              onPressed: () => setState(() => _selectedWall = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasureCard() {
    final Point2D start = _measureStart!;
    final Point2D end = _measureEnd!;
    final double horizontal = (end.x - start.x).abs();
    final double vertical = (end.y - start.y).abs();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.straighten, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distância: ${formatDecimal(start.distanceTo(end))} m',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Horizontal ${formatDecimal(horizontal)} m  |  '
                    'Vertical ${formatDecimal(vertical)} m',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Nova medição',
              onPressed: _clearMeasurement,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditLengthDialog extends StatefulWidget {
  final double initialValue;

  const _EditLengthDialog({required this.initialValue});

  @override
  State<_EditLengthDialog> createState() => _EditLengthDialogState();
}

class _EditLengthDialogState extends State<_EditLengthDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatDecimal(widget.initialValue),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? _parse(String? text) {
    if (text == null) return null;
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  String? _validate(String? value) {
    final double? number = _parse(value);
    if (number == null || !number.isFinite) {
      return 'Informe um número válido';
    }
    if (number <= 0) return 'Deve ser maior que zero';
    if (number > 100) return 'Máximo de 100 m';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_parse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Medida da parede'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Comprimento',
            suffixText: 'm',
          ),
          validator: _validate,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Aplicar')),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.highlight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
