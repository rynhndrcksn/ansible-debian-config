# Ansible Debian Configuration

This Ansible project provides a modular and extensible framework to automate the provisioning, hardening, and management of Debian servers.
It leverages best practices to ensure consistency, security, and maintainability in your infrastructure automation.

## Overview

The project includes roles and playbooks to:

- Configure and secure system access
- Manage users and permissions
- Harden SSH and firewall settings
- Install and update essential packages and software
- Automate system updates and security patches
- Configure system-level settings like timezone and hostname

## Structure

- **Inventories:** Environment-specific host and variable definitions
- **Roles:** Reusable components encapsulating logical configuration units
- **Playbooks:** Top-level orchestration scripts invoking roles and tasks
- **Vault:** Secure storage of sensitive credentials and secrets

## Features

- Environment-aware configuration for staging, production, and more
- Support for encrypted secrets using Ansible Vault
- Automated security hardening including fail2ban and firewall configuration
- User management with enforced password policies
- Package and service management tailored for Debian-based systems

## Getting Started

1. Define your inventory and environment-specific variables.
2. Customize variables and credentials securely using Ansible Vault.
3. Run playbooks targeting your infrastructure to apply configurations.
4. Extend by adding new roles and playbooks as your environment grows.

## Requirements

- Ansible 2.18+
    - Note: this might work on older versions of Ansible, but it was developed using Ansible 2.18.
- Debian 13 or newer servers
- Access with sufficient privileges to perform configuration changes

## Contributions

If you have any suggestions or fixes for this repository, feel free to open an issue to discuss it further.

## License

Copyright (c) 2025 Ryan Hendrickson. Released under the MIT License. See [LICENSE](LICENSE) for details.

---

This project is designed to be flexible and easily expandable to accommodate evolving operational needs. Contribution and customization are encouraged to fit specific deployment scenarios.

For detailed usage, role descriptions, and examples, consult the documentation and inline comments within the project files.

