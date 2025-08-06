terraform {
    backend "gcs" {
        bucket = "bookwork-466915-tfstate"
        prefix = "terraform-state/"
    }
}