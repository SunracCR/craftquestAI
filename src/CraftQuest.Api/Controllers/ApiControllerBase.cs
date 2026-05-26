using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace CraftQuest.Api.Controllers;

public abstract class ApiControllerBase : ControllerBase
{
    protected Guid GetUserId()
    {
        var value = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        if (!Guid.TryParse(value, out var userId))
        {
            throw new UnauthorizedAccessException();
        }

        return userId;
    }
}
