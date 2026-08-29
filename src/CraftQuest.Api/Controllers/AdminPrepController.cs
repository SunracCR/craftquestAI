using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.PrepPlus;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/admin/prep")]
[Authorize(Policy = "ContentAdmin")]
public class AdminPrepController(
    IPrepPlusAdminService prepPlusAdminService,
    IPrepPlusQuestionBankService prepPlusQuestionBankService) : ApiControllerBase
{
    [HttpGet("categories")]
    [ProducesResponseType(typeof(IReadOnlyList<PrepCategoryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories(
        [FromQuery] bool includeInactive = false,
        CancellationToken cancellationToken = default)
    {
        var tree = await prepPlusAdminService.GetCategoryTreeAsync(includeInactive, cancellationToken);
        return Ok(tree);
    }

    [HttpPost("categories")]
    [ProducesResponseType(typeof(PrepCategoryDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateCategory(
        [FromBody] UpsertPrepCategoryRequest request,
        CancellationToken cancellationToken)
    {
        var created = await prepPlusAdminService.CreateCategoryAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetCategories), new { includeInactive = true }, created);
    }

    [HttpPut("categories/{categoryId:guid}")]
    [ProducesResponseType(typeof(PrepCategoryDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateCategory(
        Guid categoryId,
        [FromBody] UpsertPrepCategoryRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await prepPlusAdminService.UpdateCategoryAsync(categoryId, request, cancellationToken);
        return Ok(updated);
    }

    [HttpDelete("categories/{categoryId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteCategory(
        Guid categoryId,
        CancellationToken cancellationToken)
    {
        await prepPlusAdminService.DeleteCategoryAsync(categoryId, cancellationToken);
        return NoContent();
    }

    [HttpGet("linkable-quizzes")]
    [ProducesResponseType(typeof(IReadOnlyList<PrepLinkableQuizDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListLinkableQuizzes(
        [FromQuery] string? search = null,
        [FromQuery] int take = 100,
        CancellationToken cancellationToken = default)
    {
        var quizzes = await prepPlusAdminService.ListLinkableQuizzesAsync(
            GetUserId(),
            search,
            take,
            cancellationToken);
        return Ok(quizzes);
    }

    [HttpGet("items")]
    [ProducesResponseType(typeof(IReadOnlyList<PrepCatalogItemSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListItems(
        [FromQuery] Guid? categoryId,
        [FromQuery] bool? isPublished,
        [FromQuery] bool includeDeleted = false,
        [FromQuery] string? search = null,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        var items = await prepPlusAdminService.ListCatalogItemsAsync(
            categoryId,
            isPublished,
            includeDeleted,
            search,
            skip,
            take,
            cancellationToken);
        return Ok(items);
    }

    [HttpGet("items/{catalogItemId:guid}")]
    [ProducesResponseType(typeof(PrepCatalogItemDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetItem(Guid catalogItemId, CancellationToken cancellationToken)
    {
        var item = await prepPlusAdminService.GetCatalogItemAsync(catalogItemId, cancellationToken);
        return Ok(item);
    }

    [HttpPost("items")]
    [ProducesResponseType(typeof(PrepCatalogItemDetailDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateItem(
        [FromBody] CreatePrepCatalogItemRequest request,
        CancellationToken cancellationToken)
    {
        var created = await prepPlusAdminService.CreateCatalogItemAsync(
            GetUserId(),
            request,
            cancellationToken);
        return CreatedAtAction(nameof(GetItem), new { catalogItemId = created.CatalogItemId }, created);
    }

    [HttpPut("items/{catalogItemId:guid}")]
    [ProducesResponseType(typeof(PrepCatalogItemDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateItem(
        Guid catalogItemId,
        [FromBody] UpdatePrepCatalogItemRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await prepPlusAdminService.UpdateCatalogItemAsync(
            catalogItemId,
            request,
            cancellationToken);
        return Ok(updated);
    }

    [HttpPut("items/{catalogItemId:guid}/offers")]
    [ProducesResponseType(typeof(PrepCatalogItemDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpsertOffers(
        Guid catalogItemId,
        [FromBody] UpsertPrepAccessOffersRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await prepPlusAdminService.UpsertOffersAsync(
            catalogItemId,
            request,
            cancellationToken);
        return Ok(updated);
    }

    [HttpPut("items/{catalogItemId:guid}/samples")]
    [ProducesResponseType(typeof(PrepCatalogItemDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpsertSamples(
        Guid catalogItemId,
        [FromBody] UpsertPrepSampleQuestionsRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await prepPlusAdminService.UpsertSampleQuestionsAsync(
            catalogItemId,
            request,
            cancellationToken);
        return Ok(updated);
    }

    [HttpPost("items/{catalogItemId:guid}/publish")]
    [ProducesResponseType(typeof(PrepCatalogItemDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Publish(Guid catalogItemId, CancellationToken cancellationToken)
    {
        var updated = await prepPlusAdminService.PublishCatalogItemAsync(catalogItemId, cancellationToken);
        return Ok(updated);
    }

    [HttpPost("items/{catalogItemId:guid}/unpublish")]
    [ProducesResponseType(typeof(PrepCatalogItemDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Unpublish(Guid catalogItemId, CancellationToken cancellationToken)
    {
        var updated = await prepPlusAdminService.UnpublishCatalogItemAsync(catalogItemId, cancellationToken);
        return Ok(updated);
    }

    [HttpDelete("items/{catalogItemId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteItem(Guid catalogItemId, CancellationToken cancellationToken)
    {
        await prepPlusAdminService.DeleteCatalogItemAsync(catalogItemId, cancellationToken);
        return NoContent();
    }

    [HttpGet("items/{catalogItemId:guid}/question-bank")]
    [ProducesResponseType(typeof(PrepQuestionBankDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetQuestionBank(
        Guid catalogItemId,
        CancellationToken cancellationToken)
    {
        var bank = await prepPlusQuestionBankService.GetQuestionBankAsync(catalogItemId, cancellationToken);
        return Ok(bank);
    }

    [HttpPost("items/{catalogItemId:guid}/sections")]
    [ProducesResponseType(typeof(PrepQuizSectionDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateSection(
        Guid catalogItemId,
        [FromBody] UpsertPrepQuizSectionRequest request,
        CancellationToken cancellationToken)
    {
        var created = await prepPlusQuestionBankService.CreateSectionAsync(
            catalogItemId,
            request,
            cancellationToken);
        return CreatedAtAction(nameof(GetQuestionBank), new { catalogItemId }, created);
    }

    [HttpPut("items/{catalogItemId:guid}/sections/{sectionId:guid}")]
    [ProducesResponseType(typeof(PrepQuizSectionDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateSection(
        Guid catalogItemId,
        Guid sectionId,
        [FromBody] UpsertPrepQuizSectionRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await prepPlusQuestionBankService.UpdateSectionAsync(
            catalogItemId,
            sectionId,
            request,
            cancellationToken);
        return Ok(updated);
    }

    [HttpDelete("items/{catalogItemId:guid}/sections/{sectionId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteSection(
        Guid catalogItemId,
        Guid sectionId,
        CancellationToken cancellationToken)
    {
        await prepPlusQuestionBankService.DeleteSectionAsync(catalogItemId, sectionId, cancellationToken);
        return NoContent();
    }

    [HttpPost("items/{catalogItemId:guid}/topics")]
    [ProducesResponseType(typeof(PrepQuizTopicDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateTopic(
        Guid catalogItemId,
        [FromBody] UpsertPrepQuizTopicRequest request,
        CancellationToken cancellationToken)
    {
        var created = await prepPlusQuestionBankService.CreateTopicAsync(
            catalogItemId,
            request,
            cancellationToken);
        return CreatedAtAction(nameof(GetQuestionBank), new { catalogItemId }, created);
    }

    [HttpPut("items/{catalogItemId:guid}/topics/{topicId:guid}")]
    [ProducesResponseType(typeof(PrepQuizTopicDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateTopic(
        Guid catalogItemId,
        Guid topicId,
        [FromBody] UpsertPrepQuizTopicRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await prepPlusQuestionBankService.UpdateTopicAsync(
            catalogItemId,
            topicId,
            request,
            cancellationToken);
        return Ok(updated);
    }

    [HttpDelete("items/{catalogItemId:guid}/topics/{topicId:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteTopic(
        Guid catalogItemId,
        Guid topicId,
        CancellationToken cancellationToken)
    {
        await prepPlusQuestionBankService.DeleteTopicAsync(catalogItemId, topicId, cancellationToken);
        return NoContent();
    }

    [HttpPut("items/{catalogItemId:guid}/questions/tagging")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> BulkTagQuestions(
        Guid catalogItemId,
        [FromBody] BulkTagPrepQuestionsRequest request,
        CancellationToken cancellationToken)
    {
        await prepPlusQuestionBankService.BulkTagQuestionsAsync(catalogItemId, request, cancellationToken);
        return NoContent();
    }

    [HttpPut("items/{catalogItemId:guid}/custom-practice")]
    [ProducesResponseType(typeof(PrepCatalogItemDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetCustomPractice(
        Guid catalogItemId,
        [FromBody] SetPrepCustomPracticeRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await prepPlusQuestionBankService.SetCustomPracticeAsync(
            catalogItemId,
            request,
            cancellationToken);
        return Ok(updated);
    }
}
