using Microsoft.AspNetCore.Http.Extensions;
using Microsoft.Net.Http.Headers;
using System.Net;
using System.Text.RegularExpressions;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/healthz", () => "Healthie!");

var urlRegex = new Regex("^https?:\\/\\/.+?[^\\/]*");

const string newBaseUrl = "https://www.remiceraline.com";

app.Use(async (context, next) =>
{
    var oldUrl = context.Request.GetEncodedUrl();

    if (oldUrl.EndsWith("/healthz"))
    {
        await next.Invoke();
        return;
    }

    var redirectUrl = urlRegex.Replace(oldUrl, newBaseUrl);

    var response = context.Response;
    response.StatusCode = (int)HttpStatusCode.MovedPermanently;
    response.Headers[HeaderNames.Location] = redirectUrl;

    await context.Response.WriteAsync("Redirect to www.remiceraline.com.");
});

app.Run();
