# SchoolGPT Azure Infrastructure – One-Click Deployment

## 📝 High Level Design: School-Safe AI App using AI Foundry

### Solution Overview
- This Azure-based solution lets schools use AI Foundry safely, ensuring students never see harmful content.
- **Everything is automated:** All infrastructure is created with Terraform, and the app is deployed using GitHub Actions.
- **One-click setup:** Users just fill in a few details and push to GitHub—no cloud expertise needed.

### Component Design
1. **Application Code**
   - Based on Microsoft’s [sample-app-aoai-chatGPT](https://github.com/microsoft/sample-app-aoai-chatGPT.git).
   - The sample app is imported into your repo.
   - Unnecessary code can be removed for simplicity and safety.
   - Uses Azure SQL as the backend (via Python, as in the sample).
2. **Front End**
   - Built with React (from the sample app).
   - Design is complete and ready to use.
   - **Access is secured with Entra ID** (Microsoft login, already in the sample).
   - **Application Insights** is deployed for monitoring.
   - **Chat history** is always available and stored in SQL.
3. **Back End**
   - Python backend (FastAPI), as provided in the sample app.
4. **Data Layer**
   - **Azure SQL Database** is deployed via Terraform.
   - The app reads/writes chat data using Python.
   - **Chat history** is shown on screen (from SQL).
   - **Audit table** records all chat activity.
   - **Flagged messages** (content filter triggers) are stored in a separate table.
5. **DevOps**
   - **GitHub** stores all code (app + Terraform).
   - **GitHub Actions** automates both infrastructure and app deployments.
6. **AI Foundry**
   - **Azure AI Foundry** is used for the AI model.
   - **GPT Turbo** is the default model, but you can connect to **GPT-4.1** if available.
   - **Content filter is set to high** for all settings.
   - **Prompt engineering:** Every question to AI Foundry is enriched to say the user is “under the age of 16 and needs high integrity answers.”

### What’s New in This Version
- **Fully automated:** Users don’t need to know cloud details—just fill in a few values and push to GitHub.
- **Terraform creates everything:** Even the AI Foundry resource is created and connected automatically.
- **GitHub Actions handles all deployments:** No manual steps.
- **README and templates are simple and user-friendly:** Anyone can set up their own school-safe AI app.

---

This folder contains everything you need to deploy the SchoolGPT app on Azure using Terraform. No deep cloud knowledge required!

---

## 🚀 What Does This Do?
- Creates all Azure resources needed for the SchoolGPT app:
  - Resource Group
  - Container Registry (for app images)
  - Linux Web App (runs the app)
  - SQL Database (stores chat history)
  - Application Insights (monitoring)
  - **AI Foundry (Promptflow) resource** (for safe AI chat)
- Connects everything automatically—no manual setup needed.

---

## 📝 Prerequisites
- An Azure account with permission to create resources
- [Terraform installed](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Azure CLI installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

---

## 🟢 What You Need to Fill In
Just open `terraform.tfvars` and fill in these values:

- `resource_group_name`: Name for your Azure resource group (everything will be created inside this)
- `location`: Azure region (e.g., `uksouth`, `eastus`)
- `web_app_name`: Name for your SchoolGPT app (must be globally unique)
- `sql_password`: Admin password for your SQL database (choose something secure)
- `key_vault_name`, `acr_name`, `promptflow_name`, `sql_server_name`: (Must be globally unique; you can use your app name as the base for all)
- `azure_tenant_id`: Your Azure tenant ID
- `key_vault_admin_object_id`: Your Azure AD object ID (for Key Vault access)

**Example `terraform.tfvars`:**
```hcl
resource_group_name   = "schoolgpt-rg"
location              = "uksouth"
web_app_name          = "schoolgpt-webapp123"
sql_password          = "<your-sql-password>"
key_vault_name        = "schoolgptkv123"
acr_name              = "schoolgptacr123"
promptflow_name       = "schoolgptpromptflow123"
sql_server_name       = "schoolgptsqlsrv123"
azure_tenant_id       = "<your-azure-tenant-id>"
key_vault_admin_object_id = "<your-azure-ad-object-id>"
```

---

## 🤖 Everything Else is Automatic
- **Terraform will create all resources** (Web App, SQL, ACR, Key Vault, AI Foundry, App Insights) in the resource group you specify.
- **All wiring, secrets, and connections are handled for you.**
- **No manual Azure Portal steps needed.**
- **All resources are grouped together for easy management.**

---

## 🛠️ What Gets Created
- **Resource Group:** Keeps everything organized
- **Container Registry:** Stores your app’s Docker images
- **Web App:** Runs the SchoolGPT app (frontend + backend)
- **SQL Database:** Stores chat history, audit logs, flagged messages
- **Application Insights:** For monitoring and troubleshooting
- **AI Foundry (Promptflow):** Provides safe, filtered AI chat

---

## 🧑‍💻 Need to Customize?
- You can change resource names, region, or other settings in `terraform.tfvars`.
- The app will be ready for you to push your code and start using right away!

---

## 🔑 GitHub Actions Secrets (Required for CI/CD)
If you want to deploy SchoolGPT using GitHub Actions (recommended!), you need to add some secrets to your GitHub repository:

Go to **GitHub → Settings → Secrets and variables → Actions** and add these:

- `AZURE_CLIENT_ID` – From your Azure App Registration (for GitHub Actions to log in)
- `AZURE_TENANT_ID` – Your Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` – Your Azure subscription ID
- `ACR_LOGIN_SERVER` – Your Azure Container Registry login server (e.g., myacr.azurecr.io)
- `ACR_USERNAME` – Your ACR username (get from Azure Portal or CLI)
- `ACR_PASSWORD` – Your ACR password (get from Azure Portal or CLI)

**How to get these values:**
- Ask your Azure admin if you’re not sure, or see the Azure Portal/CLI.

**Once these are set:**
- Push your code to GitHub.
- The GitHub Actions workflow will build, push, and deploy everything for you—no manual steps needed!

---

## 🗂️ About the Azure Container Registry (ACR)
- **Terraform will create a new Azure Container Registry for you!**
- You do NOT need to use an existing registry or get credentials in advance.
- Just set a unique name for `acr_name` in your `terraform.tfvars` (e.g., `schoolgptacr123`).

### How to Get Your New Registry Credentials
After you run `terraform apply` and your resources are created:

1. **Get the username and password for your new registry:**
   ```sh
   az acr credential show --name <your-new-acr-name>
   ```
   - Replace `<your-new-acr-name>` with the value you set for `acr_name`.
   - This will show you the username and password for your new registry.
2. **Add these as GitHub Actions secrets:**
   - `ACR_USERNAME`
   - `ACR_PASSWORD`

**Now your GitHub Actions pipeline can build and push Docker images to your new registry automatically!**

---

## ❓ Questions?
- If you get stuck, ask your Azure admin for help with permissions.
- For more info, see the main project README or contact your support team. 