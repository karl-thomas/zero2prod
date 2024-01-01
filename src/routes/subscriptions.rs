use actix_web::{web::Form, HttpResponse};

#[derive(serde::Deserialize)]
pub struct FormData {
    email: String,
    name: String,
}

pub async fn subscribe(_user: Form<FormData>) -> HttpResponse {
    HttpResponse::Ok().finish()
}
