"""Simple PySpark script that connects to Polaris (Iceberg REST) over MinIO and demonstrates create/insert/history for lineage/audit."""

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp

CATALOG = "demo"
NAMESPACE = "default"
TABLE = "orders"
WAREHOUSE = "s3a://demo-warehouse"
POLARIS_URI = "http://polaris:8181"
MINIO_ENDPOINT = "http://minio:9000"
MINIO_ACCESS = "minioadmin"
MINIO_SECRET = "minioadmin"


def build_spark() -> SparkSession:
    return (
        SparkSession.builder.appName("polaris-demo")
        .master("local[*]")
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .config(f"spark.sql.catalog.{CATALOG}", "org.apache.iceberg.spark.SparkCatalog")
        .config(f"spark.sql.catalog.{CATALOG}.catalog-impl", "org.apache.iceberg.rest.RESTCatalog")
        .config(f"spark.sql.catalog.{CATALOG}.uri", POLARIS_URI)
        .config(f"spark.sql.catalog.{CATALOG}.warehouse", WAREHOUSE)
        .config(f"spark.sql.catalog.{CATALOG}.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
        .config(f"spark.sql.catalog.{CATALOG}.client.endpoint", MINIO_ENDPOINT)
        .config(f"spark.sql.catalog.{CATALOG}.client.region", "us-east-1")
        .config(f"spark.sql.catalog.{CATALOG}.client.access-key-id", MINIO_ACCESS)
        .config(f"spark.sql.catalog.{CATALOG}.client.secret-access-key", MINIO_SECRET)
        .config(f"spark.sql.catalog.{CATALOG}.client.path-style-access", "true")
        .config("spark.hadoop.fs.s3a.endpoint", MINIO_ENDPOINT)
        .config("spark.hadoop.fs.s3a.path.style.access", "true")
        .config("spark.hadoop.fs.s3a.access.key", MINIO_ACCESS)
        .config("spark.hadoop.fs.s3a.secret.key", MINIO_SECRET)
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false")
        .getOrCreate()
    )


def main():
    spark = build_spark()
    spark.sql(f"CREATE NAMESPACE IF NOT EXISTS {CATALOG}.{NAMESPACE}")
    spark.sql(
        f"""
        CREATE TABLE IF NOT EXISTS {CATALOG}.{NAMESPACE}.{TABLE} (
            id bigint,
            sku string,
            qty int,
            created_at timestamp
        ) USING iceberg
        PARTITIONED BY (days(created_at))
        """
    )

    # Write a small batch
    df = spark.createDataFrame(
        [(1, "SKU-1", 2, None), (2, "SKU-2", 5, None)],
        ["id", "sku", "qty", "created_at"],
    ).withColumn("created_at", current_timestamp())
    df.writeTo(f"{CATALOG}.{NAMESPACE}.{TABLE}").append()

    # Query the table
    spark.sql(f"SELECT * FROM {CATALOG}.{NAMESPACE}.{TABLE} ORDER BY id").show(truncate=False)

    # Show table history for audit/lineage (commits, snapshots)
    spark.sql(f"SELECT * FROM {CATALOG}.{NAMESPACE}.{TABLE}.history").show(truncate=False)

    spark.stop()


if __name__ == "__main__":
    main()
