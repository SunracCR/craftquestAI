import 'package:craftquest_app/features/ai/data/models/ai_job_model.dart';

abstract class AiGenerationJobGateway {
  Future<AiJobModel> getJob(String aiJobId);

  Future<void> retryGenerationJob(String aiJobId);
}
