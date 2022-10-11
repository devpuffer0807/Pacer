from django import forms

class LogForm(forms.Form):
    user = forms.CharField(max_length=30)
    log = forms.CharField(max_length=20)
