from django import forms

from .board import COLUMNS


class DropForm(forms.Form):
    column = forms.IntegerField(min_value=1, max_value=COLUMNS)
