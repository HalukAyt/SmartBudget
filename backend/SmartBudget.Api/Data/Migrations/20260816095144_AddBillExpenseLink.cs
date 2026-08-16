using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SmartBudget.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddBillExpenseLink : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "BillId",
                table: "Expenses",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Expenses_BillId",
                table: "Expenses",
                column: "BillId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Expenses_Bills_BillId",
                table: "Expenses",
                column: "BillId",
                principalTable: "Bills",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Expenses_Bills_BillId",
                table: "Expenses");

            migrationBuilder.DropIndex(
                name: "IX_Expenses_BillId",
                table: "Expenses");

            migrationBuilder.DropColumn(
                name: "BillId",
                table: "Expenses");
        }
    }
}
