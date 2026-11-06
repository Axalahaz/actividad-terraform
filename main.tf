# --------------------------------------------------
# Alumnas: Jessica Bay y Mayra Diaz Orellana
# --------------------------------------------------

# --------------------------------------------------
# 1. PROVEEDORES
# --------------------------------------------------
terraform {
  required_providers {
    docker = {source = "kreuzwerker/docker"}
    aws    = {source = "hashicorp/aws"}
  }
}

# --------------------------------------------------
# 2. PROVEEDOR DOCKER
# --------------------------------------------------
provider "docker" {}

# --------------------------------------------------
# 3. CREACIÓN DEL CONTENEDOR FLOCI
# --------------------------------------------------
resource "docker_image" "floci" {
  name = "floci/floci:latest"
}

resource "docker_container" "floci" {
  name  = "floci"
  image = docker_image.floci.image_id
  ports {
    internal = 4566
    external = 4566
  }
}

# --------------------------------------------------
# 4. PROVEEDOR AWS APUNTANDO A FLOCI
# --------------------------------------------------
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true
  endpoints {
    s3 = "http://localhost:4566"
  }
}

# --------------------------------------------------
# 5. CREACIÓN DEL BUCKET S3
# --------------------------------------------------
resource "aws_s3_bucket" "b" {
  bucket     = "nube-cafe"
  depends_on = [docker_container.floci]
}

# --------------------------------------------------
# 6. IDENTIFICACIÓN DE LOS ARCHIVOS DEL SITIO
# SE EDITO PORQUE NO FUNCIONABA
# --------------------------------------------------

locals {
  archivos_web = fileset("${path.module}/sitio-web", "**/*")
}

# --------------------------------------------------
# 7. SUBIDA DE ARCHIVOS ESTÁTICOS
# SE EDITO PORQUE NO FUNCIONABA
# --------------------------------------------------

resource "aws_s3_object" "archivos_sitio" {
  for_each = toset(local.archivos_web)

  bucket = aws_s3_bucket.b.id
  key    = each.value

  source = "${path.module}/sitio-web/${each.value}"
  etag   = filemd5("${path.module}/sitio-web/${each.value}")

  content_type = lookup({
    "html" = "text/html"
    "css"  = "text/css"
  }, element(reverse(split(".", each.value)), 0), "application/octet-stream")
}

# --------------------------------------------------
# 8. OUTPUT
# --------------------------------------------------
output "website_url" {
  value = "http://localhost:4566/nube-cafe/index.html"
}