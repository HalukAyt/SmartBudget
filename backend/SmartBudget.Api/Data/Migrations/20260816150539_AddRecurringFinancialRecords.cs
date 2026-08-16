using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartBudget.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddRecurringFinancialRecords : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RecurringFinancialRules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    RecordType = table.Column<int>(type: "integer", nullable: false),
                    Frequency = table.Column<int>(type: "integer", nullable: false),
                    StartDate = table.Column<DateOnly>(type: "date", nullable: false),
                    EndDate = table.Column<DateOnly>(type: "date", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    BillType = table.Column<int>(type: "integer", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RecurringFinancialRules", x => x.Id);
                    table.CheckConstraint("CK_RecurringFinancialRules_BillType", "\"BillType\" IS NULL OR \"BillType\" IN (1, 2, 3)");
                    table.CheckConstraint("CK_RecurringFinancialRules_Frequency", "\"Frequency\" IN (1)");
                    table.CheckConstraint("CK_RecurringFinancialRules_RecordType", "\"RecordType\" IN (1, 2, 3)");
                    table.ForeignKey(
                        name: "FK_RecurringFinancialRules_Categories_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "Categories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_RecurringFinancialRules_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "RecurringOccurrences",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    RecurringRuleId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Year = table.Column<int>(type: "integer", nullable: false),
                    Month = table.Column<int>(type: "integer", nullable: false),
                    RecordType = table.Column<int>(type: "integer", nullable: false),
                    CreatedRecordId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RecurringOccurrences", x => x.Id);
                    table.CheckConstraint("CK_RecurringOccurrences_RecordType", "\"RecordType\" IN (1, 2, 3)");
                    table.ForeignKey(
                        name: "FK_RecurringOccurrences_RecurringFinancialRules_RecurringRuleId",
                        column: x => x.RecurringRuleId,
                        principalTable: "RecurringFinancialRules",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_RecurringOccurrences_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RecurringFinancialRules_CategoryId",
                table: "RecurringFinancialRules",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_RecurringFinancialRules_UserId",
                table: "RecurringFinancialRules",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_RecurringOccurrences_RecurringRuleId_Year_Month",
                table: "RecurringOccurrences",
                columns: new[] { "RecurringRuleId", "Year", "Month" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RecurringOccurrences_UserId",
                table: "RecurringOccurrences",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RecurringOccurrences");

            migrationBuilder.DropTable(
                name: "RecurringFinancialRules");
        }
    }
}
