// This file serves as an entry point to run all tests
import 'unit/domain/usecases/get_images_usecase_test.dart' as get_images_test;
import 'unit/domain/usecases/populate_realm_database_usecase_test.dart' as populate_realm_test;
import 'unit/data/repositories/image_repository_impl_test.dart' as repository_test;
import 'unit/data/mappers/image_mapper_test.dart' as mapper_test;
import 'unit/data/dtos/image_dto_test.dart' as dto_test;
import 'integration/gallery_integration_test.dart' as integration_test;

void main() {
  // Unit Tests
  get_images_test.main();
  populate_realm_test.main();
  repository_test.main();
  mapper_test.main();
  dto_test.main();

  // Integration Tests
  integration_test.main();
}
