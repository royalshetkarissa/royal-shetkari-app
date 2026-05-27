# SonarCloud Integration & Remediation Guide

This guide describes how to resolve the `Project not found` scanner error (Exit Code 3) and establishes secure, production-ready integration between GitHub Actions and SonarCloud for the **Royal Shetkari** project.

---

## 1. Why Did This Error Happen?
When SonarScanner runs inside GitHub Actions, it contacts the SonarCloud APIs. During this scan, the logs show:
1. `Load project settings for component key: 'royalshetkarissa_royal-shetkari-backend' (done)`
2. `Check ALM binding of project 'royalshetkarissa_royal-shetkari-backend' ... BOUND`
3. `Create analysis ... ERROR Project not found`

This sequence means that:
* The scanner successfully performed a **read-only** call to fetch settings for the project key `royalshetkarissa_royal-shetkari-backend`.
* The GitHub repository and SonarCloud project are linked (**BOUND**).
* **The analysis creation failed** because the `SONAR_TOKEN` provided to the runner lacks the **Execute Analysis** permission on this project/organization, or the token has expired or been revoked. SonarCloud returns a generic `Project not found` error rather than a permission error to prevent disclosing the existence of private resources to unauthorized users.

---

## 2. How to Verify Organization Key
1. Log in to [SonarCloud](https://sonarcloud.io/).
2. Navigate to your organization dashboard (e.g. click on your avatar in the top-right and select your organization).
3. Look at the URL or the organization page header:
   * The **Organization Key** is the identifier shown in the URL: `https://sonarcloud.io/organizations/<organization-key>/projects`.
   * For this project, it is: **`royalshetkarissa`**.
4. Double-check that it matches exactly in `backend/sonar-project.properties`:
   ```properties
   sonar.organization=royalshetkarissa
   ```

---

## 3. How to Verify Project Key
1. Inside your SonarCloud organization, click on your project **royal-shetkari-app**.
2. On the project home page, look at the bottom-right corner under **Project Information**:
   * You will find the **Project Key**.
   * It should be exactly: **`royalshetkarissa_royal-shetkari-backend`**.
3. Verify that it matches exactly in `backend/sonar-project.properties`:
   ```properties
   sonar.projectKey=royalshetkarissa_royal-shetkari-backend
   ```

---

## 4. How to Regenerate a High-Permission SONAR_TOKEN
A token with "Execute Analysis" permission is required to upload reports.
1. In SonarCloud, click on your profile picture in the upper right-hand corner and select **My Account**.
2. Go to the **Security** tab.
3. Under **Generate Tokens**:
   * Enter a name (e.g., `GitHub Actions CI Token`).
   * Click **Generate**.
4. **Copy the token immediately** (you will not be able to see it again).
5. Ensure your user account is an Administrator or has **Execute Analysis** permission in the organization:
   * Go to **Organization > Members** and verify your permissions.
   * Or go to **Project Settings > Permissions** and ensure your role has **Execute Analysis** checked.

---

## 5. How to Reconnect GitHub Repository with SonarCloud
If your binding becomes stale:
1. In SonarCloud, go to **Organization Settings > Organization binding**.
2. Click **Rebind** or update permissions to refresh the GitHub App connection.
3. Ensure the SonarCloud GitHub App has permission to access the `royalshetkarissa/royal-shetkari-app` repository.

---

## 6. How to Set Up the Secret in GitHub
1. Navigate to your GitHub repository: `https://github.com/royalshetkarissa/royal-shetkari-app`.
2. Go to **Settings > Secrets and variables > Actions**.
3. Under **Repository secrets**:
   * Find `SONAR_TOKEN`.
   * Click the edit icon (or click **New repository secret** if it doesn't exist).
   * Paste your newly generated SonarCloud token.
   * Click **Update secret** / **Add secret**.

---

## 7. Configuration Files Reference

### A. sonar-project.properties
Path: `backend/sonar-project.properties`
```properties
# SonarCloud Organization and Project Keys (Must match exactly with SonarCloud dashboard)
sonar.organization=royalshetkarissa
sonar.projectKey=royalshetkarissa_royal-shetkari-backend
sonar.projectName=royal-shetkari-backend
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

## 8. How to Test SonarCloud Access Locally
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
If the token and configurations are correct, the scan will complete successfully locally and upload the report to SonarCloud.
