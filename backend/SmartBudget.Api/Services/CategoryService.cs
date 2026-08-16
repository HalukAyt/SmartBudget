using Microsoft.EntityFrameworkCore;
using SmartBudget.Api.Data;
using SmartBudget.Api.DTOs.Categories;

namespace SmartBudget.Api.Services;

public sealed class CategoryService(AppDbContext dbContext)
{
    public async Task<IReadOnlyList<CategoryResponse>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        return await dbContext.Categories
            .AsNoTracking()
            .OrderBy(category => category.Name)
            .Select(category => new CategoryResponse(category.Id, category.Name))
            .ToListAsync(cancellationToken);
    }
}
