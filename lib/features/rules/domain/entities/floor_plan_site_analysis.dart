import '../../../plan/domain/entities/floor_plan.dart';
import '../../../plan/domain/entities/plan.dart';
import 'site.dart';

/// Adapta a planta completa ao analisador atual, que opera sobre retângulos.
class FloorPlanSiteAnalysis {
  final Plan building;
  final Site site;

  const FloorPlanSiteAnalysis({required this.building, required this.site});

  factory FloorPlanSiteAnalysis.fromFloorPlan(FloorPlan floorPlan) {
    final Plan lot = floorPlan.lot ??
        (throw ArgumentError('A planta precisa conter um terreno.'));
    final Plan building = floorPlan.buildingBoundingBox() ??
        (throw ArgumentError('A planta precisa conter ao menos um cômodo.'));

    final double lotWidth = lot.boundingWidthM;
    final double lotLength = lot.boundingHeightM;
    final double leftSetback = building.minX - lot.minX;
    final double frontSetback = lot.maxY - building.maxY;
    return FloorPlanSiteAnalysis(
      building: Plan.rectangle(
        name: floorPlan.name,
        widthM: building.boundingWidthM,
        lengthM: building.boundingHeightM,
      ),
      site: Site(
        widthM: lotWidth,
        lengthM: lotLength,
        frontSetbackM: frontSetback,
        leftSetbackM: leftSetback,
      ),
    );
  }
}
