# Unity Build Server GCE Instance Setup Commands

This document outlines the necessary shell commands to configure your Google Compute Engine (GCE) instance for a Unity build server. Execute these commands in an SSH session connected to your GCE instance.

## Step 1: Format and Mount the Persistent Disk

First, you need to prepare and mount the persistent disk that will store your Unity Hub, Editor versions, and project files.

1.  **List available block devices** to identify your attached persistent disk (e.g., `/dev/sdb`):
    ```bash
    lsblk
    ```
2.  **Format the disk.** (Replace `/dev/sdb` with the correct device name if different. **Caution: This will erase all data on the selected device.**)
    ```bash
    sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
    ```
3.  **Create a mount point directory:**
    ```bash
    sudo mkdir -p /mnt/unity_data
    ```
4.  **Mount the disk** to the created mount point (replace `/dev/sdb` if necessary):
    ```bash
    sudo mount -o discard,defaults /dev/sdb /mnt/unity_data
    ```
5.  **(Optional but Recommended) Set permissions** to allow your user to write to the mount point easily:
    ```bash
    sudo chown $(whoami):$(whoami) /mnt/unity_data
    ```
6.  **Configure automatic mounting on reboot:**
    * Get the **UUID** of your persistent disk (replace `/dev/sdb` if necessary):
        ```bash
        sudo blkid /dev/sdb
        ```
        *(Copy the `UUID="YOUR_DISK_UUID"` value from the output.)*
    * Edit the `/etc/fstab` file using a text editor (e.g., nano):
        ```bash
        sudo nano /etc/fstab
        ```
    * Add the following line to the end of the file, replacing `YOUR_DISK_UUID` with the actual UUID you copied. Ensure there are no typos:
        ```
        UUID=YOUR_DISK_UUID /mnt/unity_data ext4 discard,defaults,nofail 0 2
        ```
    * Save the file and exit the editor (in `nano`, press `Ctrl+X`, then `Y`, then `Enter`).
7.  **Test the `fstab` entry** by unmounting and then attempting to mount all entries in `fstab`:
    ```bash
    sudo umount /mnt/unity_data
    sudo mount -a
    ```
    *Verify it's mounted correctly using `df -h` or `lsblk`.*

## Step 2: Install Docker on the GCE Instance

Docker will be used to containerize your build environment.

1.  **Update package lists:**
    ```bash
    sudo apt update
    ```
2.  **Install prerequisite packages** for adding Docker's repository:
    ```bash
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    ```
3.  **Add Docker's official GPG key:**
    ```bash
    curl -fsSL [https://download.docker.com/linux/ubuntu/gpg](https://download.docker.com/linux/ubuntu/gpg) | sudo apt-key add -
    ```
4.  **Add the Docker repository** to your system's sources:
    ```bash
    sudo add-apt-repository "deb [arch=amd64] [https://download.docker.com/linux/ubuntu](https://download.docker.com/linux/ubuntu) $(lsb_release -cs) stable"
    ```
5.  **Install Docker Engine, CLI, and Containerd:**
    ```bash
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    ```
6.  **Add your user to the `docker` group** to run Docker commands without `sudo`.
    ```bash
    sudo usermod -aG docker $(whoami)
    ```
    * **Important:** You will need to log out and log back into your SSH session (or start a new shell with `newgrp docker`) for this group change to take effect.
7.  **Verify Docker installation** (after logging back in or starting a new shell):
    ```bash
    docker --version
    docker run hello-world
    ```

**Note:** When installing Unity Hub and subsequently Unity Editor versions and modules, ensure you configure them to use directories within `/mnt/unity_data` (e.g., `/mnt/unity_data/UnityEditors`, `/mnt/unity_data/UnityProjects`). For build servers, Unity Editor builds are typically run in batch mode, which doesn't require a GUI.

---

Remember to replace placeholders like `/dev/sdb`, `YOUR_DISK_UUID`, `UnityHub.AppImage` (if your filename differs), `UnityHubSetup.deb` (if your filename differs), `your-instance-name`, `/path/to/your/UnityHub.AppImage`, and `your-zone-name` with your actual values.
