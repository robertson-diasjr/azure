# Azure Cloud - Hub & Spoke deployment

This code deploys a HUB & Spoke modular infrastructure on Azure Cloud. 

## Modules

1. <b>base</b> = it´s the mandatory module which deploys the following components:
    - Resource Groups
    - Log Analytics Workspace
    - VNET
    - Subnets
    - IP Groups
    - Network Security Groups
    - Azure Firewall
    - Azure Bastion
    - Routing Tables
    - VNET Peering between HUB and Spokes

2. <b>vpn-gateway</b> = deploy the VPN Gateway for On-Premises integration. The following components are deployed at this stage:
    - Virtual Network Gateway

3. <b>vpn-connections</b> = deploy the VPN Connections to establish IPSec tunnel between HUB & On-Premises integration. The following components are deployed at this stage:
    - Local Network Gateway
    - Virtual Network Gateway Connection

4. <b>virtual-machines</b> = deploy the virtual-machines into the subnets (Spoke-1, Spoke-2 and On-Premises). Also a custom data script is loaded during VM provisioning.

5. <b>frontdoor</b> = deploy the Azure FrontDoor and the following components:
    - Dedicated VNET and Subnet to host the WebApp virtual-machine (as a sample for security isolation)
    - Network Security Group
    - VNET Peering between HUB and WebApp VNET
    - Azure FrontDoor (frontend, backend pools, probes and routing rules)
    - Azure Firewall NAT Rule
    - Web Application Firewall linked on Azure FrontDoor and loading two rules: 1) custom (block IP) and 2) Managed Rule - Default Rule Set
    - IP Groups

## Usage

You can:
1. clone this repo or
2. download the individual files (respecting the directory hierarchy). 

Up to you choose the option better fits your requirement ;-).

## Contributing

Let me know and I'll be glad to invite you !!!, then ...

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## License

- Terraform
- GNU

## Diagram
![Hub-Spoke-Diagram](https://github.com/robertson-diasjr/azure/blob/master/hub-spoke/Diagram.jpg)
