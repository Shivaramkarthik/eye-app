import boto3
from botocore.config import Config
from typing import Dict, Any
from app.core.config import settings

class StorageService:
    @staticmethod
    def get_s3_client():
        return boto3.client(
            "s3",
            endpoint_url=settings.S3_ENDPOINT,
            aws_access_key_id=settings.S3_ACCESS_KEY,
            aws_secret_access_key=settings.S3_SECRET_KEY,
            region_name=settings.S3_REGION,
            config=Config(signature_version="s3v4")
        )

    @staticmethod
    def generate_presigned_upload_url(object_name: str, expiration: int = 3600) -> Dict[str, Any]:
        """Generates a private S3 pre-signed upload URL for prescription images or reports."""
        if "placeholder" in settings.S3_ACCESS_KEY:
            # Fallback URL for dev environments
            return {
                "upload_url": f"https://api.specz.co/api/v1/storage/upload_mock/{object_name}",
                "file_path": f"s3://{settings.S3_BUCKET}/{object_name}",
                "expires_in": expiration
            }
            
        s3_client = StorageService.get_s3_client()
        url = s3_client.generate_presigned_url(
            "put_object",
            Params={"Bucket": settings.S3_BUCKET, "Key": object_name},
            ExpiresIn=expiration
        )
        return {
            "upload_url": url,
            "file_path": f"s3://{settings.S3_BUCKET}/{object_name}",
            "expires_in": expiration
        }

    @staticmethod
    def generate_presigned_download_url(object_name: str, expiration: int = 3600) -> str:
        """Generates a private S3 pre-signed download URL with expiration."""
        if "placeholder" in settings.S3_ACCESS_KEY:
            return f"https://api.specz.co/api/v1/storage/download_mock/{object_name}"
            
        s3_client = StorageService.get_s3_client()
        return s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.S3_BUCKET, "Key": object_name},
            ExpiresIn=expiration
        )
