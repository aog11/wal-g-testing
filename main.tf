terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  project = "dbre-assignment"
  credentials = file("./account.json")
  region = "us-east1"
  zone = "us-east1-b"
}

resource "google_compute_network" "vnet-us-east1" {
  name = "vnet-us-east1"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet-pgsql" {
  name = "subnet-pgsql"
  ip_cidr_range = "172.30.0.0/16"
  region = "us-east1"
  network = google_compute_network.vnet-us-east1.id
}

resource "google_compute_firewall" "pgsql_private_access" {
  name    = "fw-private-access-pgsql"
  network = google_compute_network.vnet-us-east1.name
  source_ranges = [google_compute_subnetwork.subnet-pgsql.ip_cidr_range]
  target_tags = ["pgsql-nodes"]

  allow {
    protocol = "tcp"
    ports    = ["22", "5432"]
  }
}

resource "google_compute_firewall" "public_access" {
  name    = "fw-public-access"
  network = google_compute_network.vnet-us-east1.name
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["pgsql-nodes"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_disk" "postgres-data-disk" {
  count = 2
  project = "dbre-assignment"
  name    = "postgres-data-disk-vm${count.index + 1}"
  type    = "pd-ssd"
  zone    = "us-east1-b"
  size    = 25
}

resource "google_compute_instance" "pgsql-vm" {
  count = 2
  name = "pgsql-vm${count.index + 1}"
  machine_type = "e2-standard-4"
  tags = ["pgsql-nodes"]
  network_interface {
    network = google_compute_network.vnet-us-east1.name
    subnetwork = google_compute_subnetwork.subnet-pgsql.name
    access_config {
    }
  }
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  attached_disk {
    source = google_compute_disk.postgres-data-disk[count.index].self_link
    device_name = "postgres-data-disk0"
    mode = "READ_WRITE"
  }

  metadata = {
    ssh-keys = "dbadmin:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "google_storage_bucket_iam_member" "wal_g_bucket" {
  bucket = google_storage_bucket.wal_g_bucket.name
  role = "roles/storage.admin"
  member = "serviceAccount:srvdbre@dbre-assignment.iam.gserviceaccount.com"
}

resource "google_storage_bucket" "wal_g_bucket" {
  project = "dbre-assignment"
  name          = "wal_g_bucket_170422"
  location      = "us-east1"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 15
    }
    action {
      type = "Delete"
    }
  }
}