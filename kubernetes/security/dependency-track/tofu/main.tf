
terraform {
  required_version = ">= 1.12.0, < 2.0.0"
  required_providers {
    dependencytrack = {
      source  = "SolarFactories/dependencytrack"
      version = "1.27.0"
    }
    # Only for vuln data sources, SolarFactories lacks them (issue #252)
    #   ref: https://github.com/SolarFactories/terraform-provider-dependencytrack/issues/252
    dependencytrackv5 = {
      source  = "ottramst/dependencytrack"
      version = "0.7.0"
    }
  }
}

provider "dependencytrack" {
  host = "https://dtrack.kalexlab.xyz"
  key  = var.dependency_track_api_key
}

provider "dependencytrackv5" {
  endpoint = "https://dtrack.kalexlab.xyz"
  api_key  = var.dependency_track_api_key
}
