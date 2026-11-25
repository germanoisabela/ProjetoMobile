import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/home/data/repositories/mock_project_repository.dart';

void main() {
  test('starts empty and lists a project after it is created', () async {
    final repository = MockProjectRepository();

    expect(await repository.getProjects(), isEmpty);

    final project = await repository.createProject(
      name: 'Sala de estar',
      areaM2: 18,
    );

    expect(await repository.getProjects(), [project]);
  });
}
