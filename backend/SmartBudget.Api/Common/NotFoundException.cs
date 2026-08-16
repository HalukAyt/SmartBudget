namespace SmartBudget.Api.Common;

public sealed class NotFoundException(string message) : Exception(message);
