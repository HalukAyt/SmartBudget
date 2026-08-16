namespace SmartBudget.Api.Common;

public sealed class ConflictException(string message) : Exception(message);
