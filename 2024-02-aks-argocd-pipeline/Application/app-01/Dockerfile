FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
EXPOSE 80
EXPOSE 443
COPY /output/ .
ENTRYPOINT ["dotnet", "app-01.dll"]