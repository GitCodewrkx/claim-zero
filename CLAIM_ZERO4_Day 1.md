# CLAIM ZERO4 — Day 1
## Package

**Windows (PowerShell)** · Image name **`claim-zero:latest`**

This is **Day 1** of Claim Zero. You receive a ready React app. Today you only **package** it: put the app in a Docker image and open it on your laptop.

You do **not** publish to AWS, write Terraform, or use GitHub today.

```text
  [Starter: App]──►[0 Ready]──►[1 Package]
                     laptop        Docker         localhost:8080
```

**Start here:** Stage **0**, then Stage **1**. Stop after Lab **1.6**.

---

# STAGE 0 — Prerequisites and intro

Today’s job is to prove the app runs **in a container** on your laptop. A container is a packed copy of the app plus a small web server. The packed copy is called an **image**. The name you will type is **`claim-zero:latest`**.

You will:

1. Confirm the laptop is ready (editor, WSL 2, Docker Desktop).
2. Open the project folder.
3. Write a `Dockerfile` and `.dockerignore`.
4. Build the image, open **`http://localhost:8080`**, then remove the test container. **Keep the image.**

**Laptop you need**

- 64-bit **Windows 10** or **Windows 11**, about **8 GB RAM**
- Edge or Chrome

**You do not need today:** Git, Node.js, AWS CLI, Terraform, a GitHub account, an AWS account, a Docker Hub account, or a credit card.

**Directories**

- Project root = the folder that contains `package.json`
- `cd ..` goes up one folder. Repeat `cd ..` if you are still in the wrong folder.

**Ctrl + C**

If a command occupies the terminal, click in the terminal and press **Ctrl + C**. If you see `Terminate batch job (Y/N)?`, type `Y` → **Enter**.

After any installer, close **all** terminals and the editor, then open them again.

---

## Lab 0.1 — Show file extensions

So Windows does not save `Dockerfile` as `Dockerfile.txt`.

1. Click the yellow **File Explorer** icon on the taskbar.
2. Click **View** at the top.
3. Click **Show**.
4. Click **File name extensions** so a tick appears.
5. Confirm you can see names like `notes.txt`.

---

## Lab 0.2 — Editor

You need **File → Open Folder…** and **Terminal → New Terminal**.

1. Click **Start**. Type `Visual Studio Code`. If it opens, go to step 12. **Cursor** is also fine: go to step 12.
2. Open Edge or Chrome.
3. Go to https://code.visualstudio.com/Download
4. Under **Windows**, click the **User Installer** **x64** link. Use **Arm64** only if this laptop is ARM.
5. Wait for the download.
6. Open **Downloads**. Double-click the installer.
7. If Windows asks **Do you want to allow this app**, click **Yes**.
8. Tick **I accept the agreement** → **Next**.
9. Leave the folder as default → **Next**.
10. Tick **Add to PATH** (and **Add "Open with Code"** if shown) → **Next** → **Install**. Wait.
11. Tick **Launch Visual Studio Code** → **Finish**.
12. Close the editor completely (**File → Exit**). Open it again.

---

## Lab 0.3 — WSL 2

Docker Desktop on Windows uses **WSL 2**. If a check command already succeeds, skip the installer.

1. Click **Start**.
2. Type `PowerShell`.
3. Right-click **Windows PowerShell** (or **PowerShell**).
4. Click **Run as administrator**.
5. If Windows asks **Do you want to allow this app**, click **Yes**.
6. Type this. Press **Enter**:

```bash
wsl --status
```

7. If the default version is **2**, go to Lab **0.4**.
8. If WSL is missing, type this. Press **Enter**:

```bash
wsl --install
```

9. Wait until the command finishes.
10. If Windows says you must restart: save your work → **Start** → **Power** → **Restart**. After the reboot, continue.
11. If an **Ubuntu** window asks for a UNIX username: type a short name → **Enter** → type a password twice. This is only Linux on the laptop.
12. In Administrator PowerShell, type this. Press **Enter**:

```bash
wsl --status
```

13. **Pass:** default version is **2**.
14. Type this. Press **Enter**:

```bash
wsl -l -v
```

15. **Pass:** a list of distros with version **2**, or an empty list until Docker starts.
16. Close the Administrator PowerShell window.

---

## Lab 0.4 — Docker Desktop

You do **not** need a Docker Hub account.

1. Click **Start**. Type `Docker Desktop`. If it appears, click it and go to step 16.
2. Open Edge or Chrome.
3. Go to https://docs.docker.com/desktop/setup/install/windows-install/
4. Click **Docker Desktop for Windows - x86_64** (or the Arm installer if this laptop is ARM).
5. Wait for `Docker Desktop Installer.exe` in **Downloads**.
6. Open **Downloads**. Double-click **Docker Desktop Installer**.
7. If Windows asks **Do you want to allow this app**, click **Yes**.
8. If the installer asks **per-user** or **all users**, leave **per-user** selected.
9. On Configuration, tick **Use WSL 2 instead of Hyper-V** if the box is shown.
10. Click **Ok** / **Install**. Wait.
11. Click **Close** when the installer finishes. Restart the PC if the installer asks.
12. Click **Start** → **Docker Desktop**.
13. If **Docker Subscription Service Agreement** appears, click **Accept**.
14. You may skip **Sign in** / Docker Hub.
15. Wait until Docker Desktop says **running** (not “starting”). First start can take several minutes.
16. In the editor, kill old terminals. Click **Terminal → New Terminal**.
17. Type this. Press **Enter**:

```bash
docker --version
```

18. **Pass:** `Docker version` followed by numbers.
19. Type this. Press **Enter**:

```bash
docker info
```

20. **Pass:** output includes `Server` and does **not** say `Cannot connect to the Docker daemon`. **Fail:** wait until the whale icon is steady, new terminal, retry.

---

## Lab 0.5 — Open the project folder

The project root is the folder that contains `package.json`.

1. Find the project zip (File Explorer → **Downloads**, or Desktop).
2. If it is still in email: click the attachment → **Download** / **Save**.
3. If you were given a folder instead of a zip, skip to step 7.
4. Right-click the zip.
5. Click **Extract All…**.
6. Click **Extract**. Wait until a folder opens.
7. Look for **`package.json`**.
8. If you only see another folder with the same name, double-click it. Use the folder that **contains** `package.json`.
9. Open Visual Studio Code or Cursor.
10. Click **File**.
11. Click **Open Folder…**.
12. Click the project root.
13. Click **Select Folder**.
14. If asked **Do you trust the authors of the files in this folder?**, click **Yes, I trust the authors**.
15. On the left, click the **Explorer** icon (two pages) if the file list is hidden.
16. Confirm you see `package.json`, a folder named `src`, and `index.html`.
17. Click **Terminal → New Terminal**.
18. Read the path before `>`. Example: `PS C:\Users\you\claim-zero-AWS>`
19. If the path ends with `\src` or `\terraform`, type `cd ..` → **Enter**. Repeat until the folder with `package.json` is current.

**Stop here until:** file extensions on, editor open, WSL default version **2**, Docker Desktop **running**, `docker info` OK, project folder open.

---

# STAGE 1 — Package (Docker)

Build **`claim-zero:latest`** and open it at **`http://localhost:8080`**.

---

## Lab 1.1 — Confirm Docker Engine readiness

Start Docker before any `docker` command.

**Steps**

1. Open **Docker Desktop**.
2. Wait until the engine status is **running**.

---

## Lab 1.2 — Create `Dockerfile`

Create **`Dockerfile`** in the project root and paste the recipe.

**Steps**

1. Project root → **New File** → `Dockerfile`.
2. Paste the block below.
3. Press **Ctrl + S**.

```dockerfile
FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

---

## Lab 1.3 — Create `.dockerignore`

Create **`.dockerignore`** in the project root.

**Steps**

1. Project root → **New File** → `.dockerignore`.
2. Paste the block below.
3. Press **Ctrl + S**.

```text
# Dependencies are installed inside the image (do not copy the laptop's node_modules).
node_modules

# Build output is produced inside the image (Lab 1.2 RUN npm run build).
dist

# VCS metadata is not required in the build context.
.git
.gitignore

Dockerfile

# Documentation and local tooling should not bloat the context.
# terraform/ is authored in Stage 3 and is not part of the React image.
README.md
*.md
.oxlintrc.json
```

---

## Lab 1.4 — Build the image

Build **`claim-zero:latest`** from the project root.

**Steps**

1. Go to the folder that contains `Dockerfile` and `package.json`. Use `cd ..` if you are too deep.
2. Press **Ctrl + C** if `npm run dev` is still running.
3. Run:

```bash
docker build -t claim-zero:latest .
```

4. Wait until the build finishes.

---

## Lab 1.5 — Run a local verification container

Open the image at **`http://localhost:8080`**.

**Steps**

1. Stay in the **project root**.
2. Run:

```bash
docker run -d -p 8080:80 --name claim-zero-container claim-zero:latest
```

3. Open **`http://localhost:8080`**.
4. Confirm the landing page.

---

## Lab 1.6 — Remove the local test container

Stop and remove the test container. Keep the image.

**Steps**

1. Run:

```bash
docker stop claim-zero-container
```

2. Run:

```bash
docker rm claim-zero-container
```

**Day 1 is done when:** image `claim-zero:latest` exists, the page loaded at **`http://localhost:8080`**, the test container is gone, the image is still there.

Do not go on to AWS, Terraform, or GitHub in this file.
