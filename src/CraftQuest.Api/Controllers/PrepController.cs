using CraftQuest.Application.Contracts;
using CraftQuest.Application.Models.Billing;
using CraftQuest.Application.Models.PrepPlus;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

[ApiController]
[Route("api/prep")]
[Authorize]
public class PrepController(
    IPrepPlusCatalogService prepPlusCatalogService,
    IPrepPlusPaymentService prepPlusPaymentService) : ApiControllerBase
{
    [HttpGet("categories")]
    [ProducesResponseType(typeof(IReadOnlyList<PrepCategoryPublicDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories(CancellationToken cancellationToken)
    {
        var tree = await prepPlusCatalogService.GetPublicCategoryTreeAsync(cancellationToken);
        return Ok(tree);
    }

    [HttpGet("categories/{categoryId:guid}/items")]
    [ProducesResponseType(typeof(IReadOnlyList<PrepCatalogBrowseItemDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> BrowseCategoryItems(
        Guid categoryId,
        [FromQuery] string? search,
        [FromQuery] string? priceFilter,
        [FromQuery] string? institutionTag,
        [FromQuery] List<string>? tags,
        [FromQuery] string? userAccessFilter,
        [FromQuery] int skip = 0,
        [FromQuery] int take = 20,
        CancellationToken cancellationToken = default)
    {
        var items = await prepPlusCatalogService.BrowseCategoryItemsAsync(
            GetUserId(),
            categoryId,
            search,
            priceFilter,
            institutionTag,
            tags,
            userAccessFilter,
            skip,
            take,
            cancellationToken);
        return Ok(items);
    }

    [HttpGet("items/{catalogItemId:guid}")]
    [ProducesResponseType(typeof(PrepCatalogItemPublicDetailDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetItem(Guid catalogItemId, CancellationToken cancellationToken)
    {
        var item = await prepPlusCatalogService.GetPublicItemAsync(
            GetUserId(),
            catalogItemId,
            cancellationToken);
        return Ok(item);
    }

    [HttpGet("items/{catalogItemId:guid}/preview")]
    [ProducesResponseType(typeof(PrepPreviewDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPreview(Guid catalogItemId, CancellationToken cancellationToken)
    {
        var preview = await prepPlusCatalogService.GetPreviewAsync(catalogItemId, cancellationToken);
        return Ok(preview);
    }

    [HttpGet("my-accesses")]
    [ProducesResponseType(typeof(PrepMyAccessesDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyAccesses(CancellationToken cancellationToken)
    {
        var accesses = await prepPlusCatalogService.GetMyAccessesAsync(GetUserId(), cancellationToken);
        return Ok(accesses);
    }

    [HttpPost("items/{catalogItemId:guid}/checkout")]
    [ProducesResponseType(typeof(PrepCheckoutResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> Checkout(
        Guid catalogItemId,
        [FromBody] PrepCheckoutRequest request,
        CancellationToken cancellationToken)
    {
        var result = await prepPlusCatalogService.CheckoutAsync(
            GetUserId(),
            catalogItemId,
            request,
            cancellationToken);
        return Ok(result);
    }

    [HttpPost("items/{catalogItemId:guid}/paypal/create-order")]
    [ProducesResponseType(typeof(PayPalCreateOrderResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> CreatePayPalOrder(
        Guid catalogItemId,
        [FromBody] PrepPayPalCreateOrderRequest request,
        CancellationToken cancellationToken)
    {
        var result = await prepPlusPaymentService.CreatePayPalOrderAsync(
            GetUserId(),
            catalogItemId,
            request.OfferId,
            cancellationToken);
        return Ok(result);
    }

    [HttpPost("paypal/capture-order")]
    [ProducesResponseType(typeof(PrepCheckoutResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> CapturePayPalOrder(
        [FromBody] PayPalCaptureOrderRequest request,
        CancellationToken cancellationToken)
    {
        var result = await prepPlusPaymentService.CapturePayPalOrderAsync(
            GetUserId(),
            request,
            cancellationToken);
        return Ok(result);
    }

    [HttpPost("mobile/verify-purchase")]
    [ProducesResponseType(typeof(PrepCheckoutResultDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> VerifyMobilePurchase(
        [FromBody] PrepMobilePurchaseRequest request,
        CancellationToken cancellationToken)
    {
        var result = await prepPlusPaymentService.VerifyMobilePurchaseAsync(
            GetUserId(),
            request,
            cancellationToken);
        return Ok(result);
    }
}
