import os
import functions_framework
import flask
import requests

_RECAPTCHA_URL = 'https://www.google.com/recaptcha/api/siteverify'
_RECAPTCHA_SECRET = os.getenv('RECAPTCHA_KEY')
_GOOGLE_FORM_URL = os.getenv('GOOGLE_FORM_URL')


@functions_framework.http
def contact_form(request: flask.Request):

  form = request.form.copy()
  user_recaptcha = form.pop('g-recaptcha-response', None)

  recaptcha_response = requests.get(
      _RECAPTCHA_URL,
      params={'secret': _RECAPTCHA_SECRET, 'response': user_recaptcha},
  )
  if (status_code := recaptcha_response.status_code) == 200:
    if not recaptcha_response.json()['success']:
      error_codes = recaptcha_response.json().get('error-codes')
      return f'Failed reCAPTCHA, {error_codes=}', 404
  else:
    return f'Failed reCAPTCHA. {status_code=}', 404

  form_response = requests.post(_GOOGLE_FORM_URL, params=form)
  if (status_code := form_response.status_code) == 200:
    return flask.redirect('https://tomward.dev/contact/thanks/')
  else:
    return f'Error {status_code=}', status_code
