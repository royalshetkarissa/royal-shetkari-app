# SonarCloud Integration & Remediation Guide

This guide describes how to resolve the `Project not found` and `Failed to check if project is bound` errors (Exit Code 3) and establishes secure, production-ready integration between GitHub Actions and SonarCloud for the **Royal Shetkari** project.

---

## 1. Why Does “Project not found” or "Failed to check if project is bound" Still Occur?
Even when a project exists on SonarCloud with the correct key (`royalshetkarissa_royal-shetkari-app`), the scanner can still fail with these errors. This happens because:
* **Token Scope & Permissions (Read/Write Mismatch)**: The SonarScanner needs to make authenticated calls to SonarCloud. If the token is valid but doesn't have permissions to write analysis or check bindings, SonarCloud returns a `404 Not Found` (disguised as `Project not found`) or reports that it failed to check if the project is bound. This is a security measure to prevent unauthorized users from discovering private project keys.
* **Stale ALM / Repository Binding**: If the connection between GitHub and SonarCloud is disrupted (e.g., due to updated GitHub organization member access, expired GitHub OAuth permissions, or incorrect SonarCloud App permissions), the project binding check will fail.
* **Private Project Settings**: If the project is private on SonarCloud, a standard public/unprivileged token cannot see it, resulting in the scanner reporting the project as "not found".

---

## 2. Reconnecting GitHub Repository Binding in SonarCloud
If your repository binding has become stale or disconnected:
1. Log in to [SonarCloud](https://sonarcloud.io/).
2. Navigate to your organization: **royalshetkarissa**.
3. Go to **Organization Settings** > **Organization binding** (in the left navigation panel).
4. You will see your GitHub organization binding. If there is a warning or disconnect message, click **Rebind** or **Update connection**.
5. You will be redirected to GitHub to authenticate. Make sure to approve all permissions requested by the SonarCloud integration.
6. Verify that the repository `royalshetkarissa/royal-shetkari-app` is selected under the allowed repositories list for the SonarCloud GitHub App installation.

---

## 3. Verifying Repository & Organization Permissions
To allow SonarCloud to analyze your repository:
* **GitHub Repository Permissions**:
  1. Go to your GitHub repository > **Settings** > **Integrations** > **Installed GitHub Apps**.
  2. Verify that **SonarCloud** is listed and has permission to access your repository.
* **SonarCloud Organization Permissions**:
  1. Go to **SonarCloud** > Select your organization **royalshetkarissa**.
  2. Click on **Members** (or **Administer Organization**).
  3. Ensure that the user generating the `SONAR_TOKEN` has the **Administer** permission on the organization, or at least the **Execute Analysis** permission.

---

## 4. Verifying SONAR_TOKEN Access to Private Projects
If your repository/project is private:
1. In SonarCloud, select the project **royal-shetkari-app**.
2. Go to **Project Settings** > **Permissions**.
3. Under the permissions table, check the role assigned to the user or token you are using:
   * The role **must** have **Execute Analysis** and **Provision Projects** checked.
   * If using a project-specific analysis token, ensure it is generated from the project's own settings page under **Administration** > **Analysis Tokens**.

---

## 5. Regenerating a Secure SONAR_TOKEN
If the token is expired, corrupted, or has insufficient scopes, regenerate it:
1. Click on your profile picture in the top-right corner of SonarCloud and select **My Account**.
2. Go to the **Security** tab.
3. In the **Generate Tokens** field:
   * Type a descriptive name (e.g. `GitHub_Actions_Royal_Shetkari`).
   * Click **Generate**.
4. **Copy the token immediately** (it will not be shown again).

---

## 6. Configuring the Token in GitHub Secrets
To make the token available securely to your GitHub Actions:
1. Go to your GitHub repository: `https://github.com/royalshetkarissa/royal-shetkari-app`.
2. Navigate to **Settings** > **Secrets and variables** > **Actions**.
3. Click **New repository secret** (or update the existing `SONAR_TOKEN` secret):
   * **Name**: `SONAR_TOKEN`
   * **Value**: Paste the generated token.
4. Click **Add secret** / **Update secret**.

---

## 7. How to Verify ALM Binding Status
To verify if your project is successfully bound:
1. In SonarCloud, navigate to your project **royal-shetkari-app**.
2. Look at the top-left corner under the project name:
   * You should see a small **GitHub icon** next to the project name.
   * If it is unbound, a warning or "Unbound" badge will appear, and you will be prompted to link it to its corresponding GitHub repository.

---

## 8. Verification Checklist Before Push
Before committing your configuration, make sure you checked:
- [ ] Is `sonar.projectKey` set to exactly `royalshetkarissa_royal-shetkari-app` in `backend/sonar-project.properties`?
- [ ] Is `sonar.organization` set to exactly `royalshetkarissa` in `backend/sonar-project.properties`?
- [ ] Is `sonar.host.url` set to `https://sonarcloud.io` in `backend/sonar-project.properties`?
- [ ] Does `.github/workflows/ci.yml` run the Sonar step with `uses: SonarSource/sonarqube-scan-action@v6`?
- [ ] Does the GitHub workflow step pass the `projectBaseDir: ./backend` parameter?
- [ ] Did you update the `SONAR_TOKEN` in the repository secrets on GitHub?

---

## 9. Configuration Files Reference

### A. sonar-project.properties
Path: `backend/sonar-project.properties`
```properties
# SonarCloud Organization and Project Keys (Must match exactly with SonarCloud dashboard)
sonar.organization=royalshetkarissa
sonar.projectKey=royalshetkarissa_royal-shetkari-app
sonar.projectName=royal-shetkari-app
sonar.projectVersion=1.0.0
sonar.host.url=https://sonarcloud.io

# Path to source directories
sonar.sources=src
sonar.tests=tests
sonar.test.inclusions=tests/**/*.test.js,tests/**/*.spec.js

# Exclusions
sonar.exclusions=**/node_modules/**,**/logs/**,**/uploads/**,**/access.log,**/history.log

# Encoding of the source files
sonar.sourceEncoding=UTF-8

# JavaScript specifications
sonar.javascript.environments=node
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

### B. GitHub Actions CI Workflow
Path: `.github/workflows/ci.yml` (Excerpt)
```yaml
      - name: SonarQube Scan
        uses: SonarSource/sonarqube-scan-action@v6
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          projectBaseDir: ./backend
```

---

## 10. How to Test SonarCloud Access Locally
Before committing or pushing your changes, you can verify your configuration and credentials locally.

### Method A: Using Docker (Recommended)
If you have Docker installed, you can run the scanner locally from the root folder:
```bash
docker run --rm \
  -e SONAR_TOKEN="your_regenerated_sonar_token" \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectBaseDir=/usr/src/backend
```

### Method B: Using local SonarScanner CLI
1. Download and extract the SonarScanner CLI for your OS.
2. Add the `bin/` folder of the extracted package to your system's PATH.
3. Run the following command from the root directory of the project:
   ```bash
   sonar-scanner \
     -Dsonar.token="your_regenerated_sonar_token" \
     -Dsonar.projectBaseDir=./backend
   ```
