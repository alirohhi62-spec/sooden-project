

sealed class Result<ConnectionManagerDataModel, ConnectionErrorCode> {
  const Result._();

  factory Result.success(ConnectionManagerDataModel data) =
      Success<ConnectionManagerDataModel, ConnectionErrorCode>;

  factory Result.failure(ConnectionErrorCode error) =
      Failure<ConnectionManagerDataModel, ConnectionErrorCode>;

  factory Result.loading() = Loading<ConnectionManagerDataModel, ConnectionErrorCode>;



  bool get isSuccess => this is Success<ConnectionManagerDataModel, ConnectionErrorCode>;

  bool get isFailure => this is Failure<ConnectionManagerDataModel, ConnectionErrorCode>;

  bool get isLoading => this is Loading<ConnectionManagerDataModel, ConnectionErrorCode>;



  ConnectionManagerDataModel? get successValue {
    if (this is Success<ConnectionManagerDataModel, ConnectionErrorCode>) {
      return (this as Success<ConnectionManagerDataModel, ConnectionErrorCode>).data;
    }
    return null;
  }

  ConnectionErrorCode? get failureValue {
    if (this is Failure<ConnectionManagerDataModel, ConnectionErrorCode>) {
      return (this as Failure<ConnectionManagerDataModel, ConnectionErrorCode>).error;
    }
    return null;
  }
}



class Success<ConnectionManagerDataModel, ConnectionErrorCode>
    extends Result<ConnectionManagerDataModel, ConnectionErrorCode> {
  final ConnectionManagerDataModel data;

  const Success(this.data) : super._();
}

class Failure<ConnectionManagerDataModel, ConnectionErrorCode>
    extends Result<ConnectionManagerDataModel, ConnectionErrorCode> {
  final ConnectionErrorCode error;

  const Failure(this.error) : super._();
}

class Loading<ConnectionManagerDataModel, ConnectionErrorCode>
    extends Result<ConnectionManagerDataModel, ConnectionErrorCode> {
  const Loading() : super._();
}
