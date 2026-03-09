provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# -----------------------------
# VPC Network
# -----------------------------
resource "google_compute_network" "vpc_network" {
  name                    = "music-app-vpc"
  auto_create_subnetworks = false
}

# -----------------------------
# Subnet
# -----------------------------
resource "google_compute_subnetwork" "subnet" {
  name          = "music-app-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# -----------------------------
# Firewall
# -----------------------------
resource "google_compute_firewall" "allow_app" {
  name    = "allow-app-traffic"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# -----------------------------
# Private IP for Cloud SQL
# -----------------------------
resource "google_compute_global_address" "private_ip_address" {
  name          = "music-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# -----------------------------
# Cloud SQL Instance
# -----------------------------
resource "google_sql_database_instance" "mysql_instance" {
  name             = "music-sql-instance"
  database_version = "MYSQL_8_0"
  region           = var.region
  deletion_protection = false 

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# -----------------------------
# Database
# -----------------------------
resource "google_sql_database" "music_db" {
  name     = "musicdb"
  instance = google_sql_database_instance.mysql_instance.name
}

# -----------------------------
# DB User
# -----------------------------
resource "google_sql_user" "music_user" {
  name     = "musicuser"
  instance = google_sql_database_instance.mysql_instance.name
  password = "Music@123"
}

# -----------------------------
# VM Instance
# -----------------------------
resource "google_compute_instance" "vm_instance" {
  name         = "music-app-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
    }
  }

  metadata_startup_script = <<-EOT
#!/bin/bash
apt update -y
apt install -y curl

# Install NodeJS
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

mkdir -p /home/music-app
cd /home/music-app

npm init -y
npm install express mysql cors

cat > server.js <<EOF
const express = require("express");
const mysql = require("mysql");
const cors = require("cors");

const app = express();
app.use(cors());

const db = mysql.createConnection({
  host: "${google_sql_databaese_instance.mysql_instance.private_ip_address}",
  user: "musicuser",
  password: "Music@123",
  database: "musicdb"
});

db.connect(err => {
  if (err) {
    console.error("DB connection failed:", err);
  } else {
    console.log("Connected to Cloud SQL");
  }
});

app.get("/", (req, res) => {
  res.send("🎵 Music App Connected to Cloud SQL!");
});

app.listen(3000, () => {
  console.log("Server running on port 3000");
});
EOF

node server.js > app.log 2>&1 &
EOT

  tags = ["music-app"]

  depends_on = [
    google_sql_database.music_db,
    google_sql_user.music_user
  ]
}

resource "google_storage_bucket" "music_bucket" {
  name     = "${var.project_id}-music-bucket"
  location = var.region
  uniform_bucket_level_access = true
<<<<<<< HEAD
}

 
=======
}
>>>>>>> bbda465 (added)
