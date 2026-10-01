from django.urls import path

from . import views

app_name = "game"

urlpatterns = [
    path("", views.board, name="board"),
    path("move/", views.move, name="move"),
    path("reset/", views.reset, name="reset"),
]
