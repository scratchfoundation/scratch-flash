var Scratch = Scratch || {};
Scratch.Registration = Scratch.Registration || {};


function getOrigin() {
  // IE doesn't have window.location.origin
  return window.location.protocol + '//' + window.location.hostname;
}

function launchRegistration(e){
  $('#login-dialog').modal('hide');
  /* TODO: Come up with a better way to handle slide off & on double animation */
  $('#educator-registration-confirm').modal('hide');
  if (e) e.preventDefault();
  if (Scratch.Registration.modal) {
    Scratch.Registration.modal.close();
  }
  $('#registration').append($('<div id="registration-data"/>'));
  Scratch.Registration.modal =  new Scratch.Registration.RegistrationView({el: '#registration-data'});

  if (location.href.indexOf('editor')>=0) {
    $('#registration-iframe').css('z-index', '0');
  }

  $('#registration').modal('show');
}

function setUpRegistration(){
  $('[data-control="registration"]').on('click', launchRegistration);

  if (location.href.indexOf('editor')>=0) {
    $('#registration').on('hidden', function() {
      $('#registration-iframe').css('z-index', '-1');
    });
  }

  $('#registration-done').on('click', function(e) {
    _gaq.push(['_trackEvent', 'registration', 'register-complete']);
  });
}

$(document).on('accountnavready', setUpRegistration);


Scratch.Registration.RegistrationView = Backbone.View.extend({
  events:{
     'blur .username': 'validateUsername',
     'blur .password': 'validatePassword',
     'blur .password-confirm': 'validatePasswordMatch',
     'blur .email': 'validateEmail',
     'blur .email-confirm': 'validateEmailMatch',
     'blur .gender_other_text': 'validateGenderInput',
     'keydown .username': 'clear',
     'keydown .password': 'clear',
     'keydown .password-confirm': 'clear',
     'keydown .email': 'clear',
     'keydown .email-confirm': 'clear',
     'change input[name="gender"]': 'clear',
     'change select.birthyear': 'clear',
     'click .modal-footer .button': 'submit',
     'submit #registration-form': 'submit',
     'change select.birthmonth': 'checkAge',
     'change select.birthmonth': 'clear',
     'change select.birthyear': 'clear',
     'change select.birthyear': 'checkAge',
     'change select.country': 'clear',
     'click [data-dismiss="modal"]': 'dismiss',
     'click [data-control="registration"]': 'onLaunchRegistration',
     'click [data-control="login"]': 'onShowLogin',
     'click [data-control="download-project"]': 'onDownloadProject'
  },

  modalUrl: '/accounts/modal-registration/',
  postUrl: '/accounts/register_new_user/',
  registrationStep: 3, // sumbit on this step triggers registration
  finalStep: 4, // submit on this step closes the registration modal
  totalSteps: 4, // used to set progress classes

  initialize: function() {
    this.$el.load(this.modalUrl, function(data) {this.initData(data)}.bind(this));

    _.bindAll(this, 'onSubmit')
    _.bindAll(this, 'onError')
    _.bindAll(this, 'ohNoesPage')
  },

  initData: function(data) {
    if (data[0] === '/') {
        // if url, redirect to it
        window.location.href = data;
        return;
    }
    this.initBirthYear();
    this.initStep();

    // put focus on the first field
    setTimeout(function() {this.$('input:first').focus();}.bind(this), 200);
  },

  initBirthYear: function(){
    // create birth year dropdown
    var year = new Date().getFullYear(),
    firstYear = year-120,
    options = [];
    for(;year > firstYear; year--){
      options.push('<option value="'+year+'">'+year+'</option>');
    }
    this.$('.birthyear').append(options.join(''));
  },

  initStep: function(){
    var $warning = this.$('.reg-body-0');
    if ($warning.length) {
        // show ban warning
        this.step = 0;
        if ($warning.attr('data-isblocked') == 'True') {
            this.$('.registration-next').remove();
            this.$('.registration-close').show();
        }
    } else {
        this.step = 1;
        this.setFormProgress();
    }
  },

  hasErrors: function() {
    if (this.$('.reg-body-' + this.step + ' .error').length == 0 && this.step !== -1) {
      return false;
    }
    return true;
  },

  clear: function(e) {
    $(e.target).parents('.controls.error').removeClass('error')
  },

  validateUsername: function(e) {
    var username = this.$('.username').val();
    var flag = false; // true if there are any errors in the username
    var $usernameError = this.$('[data-content="username-error"] .text');

    // only through the empty error when hitting next not on blur - otherwise it's annoying
    if (!username.length && !e) {
      $usernameError.html(Scratch.Registration.FORM_ERRORS['usernameEmpty']);
      flag = true;
    }

    if (username.length) {
      if(username.length < 3 || username.length > 20) {
        $usernameError.html(Scratch.Registration.FORM_ERRORS['usernameLength']);
        flag = true;
      }
      else if (!(/^[a-zA-Z0-9_-]+$/).test(this.$('.username').val())) {
        $usernameError.html(Scratch.Registration.FORM_ERRORS['usernameCharacters']);
        flag = true;
      }
      // verify with the server that the username isn't taken
      if (!flag) {
        $.ajax({
          url: '/accounts/check_username/' + username + '/',
          success: function(response) {
            var msg = response[0].msg;
            if (msg == 'username exists') {
              $usernameError.html(Scratch.Registration.FORM_ERRORS['usernameExists']);
              flag = true;
            } else if (msg == 'bad username') {
              $usernameError.html(Scratch.Registration.FORM_ERRORS['usernameBad']);
              _gaq.push(['_trackEvent', 'registration-bad-usernames', username]);
              flag = true;
            } else if (msg == 'invalid username') {
              $usernameError.html(Scratch.Registration.FORM_ERRORS['usernameInvalid']);
              flag = true;
            }
          }.bind(this),
          async: false,
        });
      }
    }

    if (flag) {
      this.$('.username').parents('.controls').addClass('error');
    } else {
      $('.username-welcome').text(username);
    }
  },

  validatePassword: function(e) {
    var password = this.$('.password').val();
    var flag = false; // true if there were any errors in the password
    var $passwordError = this.$('[data-content="password-error"] .text');

    if (!password.length && !e) {
      $passwordError.html(Scratch.Registration.FORM_ERRORS['passwordEmpty']);
      flag = true;
    }
    if (password.length) {
      if (password.toLowerCase() == this.$('.control-group .username').val().toLowerCase()) {
        $passwordError.html(Scratch.Registration.FORM_ERRORS['passwordUsername']);
        flag = true;
      }
      else if (password == 'password') {
        $passwordError.html(Scratch.Registration.FORM_ERRORS['passwordPassword']);
        flag = true;
      }
      else if (password.length < 6) {
        $passwordError.html(Scratch.Registration.FORM_ERRORS['passwordLength']);
        flag = true;
      }
    }
    if (flag) {
      this.$('.password').parents('.controls').addClass('error');
    }
  },

  validatePasswordMatch: function(e) {
    var password = this.$('.password').val();
    var passwordConfirm = this.$('.password-confirm').val();
    var flag = false;
    var $passwordConfirmError = this.$('[data-content="password-confirm-error"] .text');

    if (!(password == passwordConfirm)) {
      $passwordConfirmError.html(Scratch.Registration.FORM_ERRORS['passwordConfirm']);
      flag = true;
    }

    if (flag) {
      this.$('.password-confirm').parents('.controls').addClass('error');
    }

  },

  validateGenderInput: function() {
    var flag = false;
    var $genderError = this.$('[data-content="gender-error"] .text');
    if (this.$('[name="gender"]:checked').size() == 0) {
      $genderError.html(Scratch.Registration.FORM_ERRORS['genderEmpty']);
      flag = true;
    } else if (this.$('input[name="gender"]:checked').val().length == 0 &&
               this.$('#gender_other_text').val().length == 0) {
      $genderError.html(Scratch.Registration.FORM_ERRORS['genderEmpty']);
      flag = true;
    }
    if (flag) {
      this.$('[data-content="gender-error"]').parents('.controls').addClass('error')
    }
  },

  validateEmail: function() {
    var flag = false; // true if there were any errors in email
    var emailAddress = this.$('.email').val();
    var $emailError = this.$('[data-content="email-error"] .text');

    if (!emailAddress.length) {
      $emailError.html(Scratch.Registration.FORM_ERRORS['emailEmpty']);
      flag = true;
    }
    else if (!(/\S+@\S+\.\S+/).test(emailAddress)) {
      $emailError.html(Scratch.Registration.FORM_ERRORS['emailInvalid']);
      flag = true;
    }
    if (!flag) {
      $.ajax({
        url: '/accounts/check_email/',
        type: 'GET',
        data: {
          email: emailAddress
        },
        success: function(response) {
          var msg = response[0].msg;
          if (msg != 'valid email') {
            $emailError.html(msg);
            flag = true;
          }
        }.bind(this),
        async: false,
      });
    }

    if (flag) {
      this.$('.email').parents('.controls').addClass('error')
    }
  },

  validateEmailMatch: function() {
    var email = this.$('.email').val();
    var emailConfirm = this.$('.email-confirm').val();
    var flag = false;
    var $emailConfirmError = this.$('[data-content="email-confirm-error"] .text');

    if (!(email == emailConfirm)) {
      $emailConfirmError.html(Scratch.Registration.FORM_ERRORS['emailConfirm']);
      flag = true;
    }

    if (flag) {
      this.$('.email-confirm').parents('.controls').addClass('error');
    } else {
      $('.email-welcome').text(email);
    }
  },

  validateBirthday: function() {
    var flag = false; // true if there were any errors in birthday
    var $birthdayError = this.$('[data-content="birthday-error"] .text');
    if ((this.$('.birthmonth').val()==0) || (this.$('.birthyear').val()==0)) {
      $birthdayError.html(Scratch.Registration.FORM_ERRORS['birthdayEmpty']);
      flag = true;
    }
    if (flag) {
      this.$('.birthmonth').parents('.controls').addClass('error');
    }
  },

  validateCountry: function() {
    var flag = false;
    var $countryError = this.$('[data-content="country-error"] .text');
    if (this.$('.country').val()==0) {
      $countryError.html(Scratch.Registration.FORM_ERRORS['countryEmpty']);
      flag= true;
    }
    if (flag) {
      this.$('.country').parents('.controls').addClass('error');
    }
  },


  validateFields: function() {
    if (this.step == 1) {
      this.validateUsername();
      this.validatePassword();
      this.validatePasswordMatch();
    } else if (this.step == 2) {
      this.validateBirthday();
      this.validateGenderInput();
      this.validateCountry();
    } else if (this.step == 3) {
      this.validateEmail();
      this.validateEmailMatch();
    }
  },

  checkAge: function() {
    if (this.$('.birthyear').val() == 0 || this.$('.birthmonth').val() == 0){
      return;
    }
    var today = new Date(),
    currentYear = today.getFullYear(),
    yearsOld = currentYear - this.$('.birthyear').val();
    if ((today.getMonth() - this.$('.birthmonth').val()) < 0) yearsOld--;
    if (yearsOld < 16) {
     this.$('label[for="email"]').hide();
     this.$('label.parents[for="email"]').show();

     this.$('.page-header h4.kids').hide();
     this.$('.page-header h4.parents').show();
    } else {
     this.$('label[for="email"]').show();
     this.$('label.parents[for="email"]').hide();

     this.$('.page-header h4.kids').show();
     this.$('.page-header h4.parents').hide();
    }

  },

  usernameExists: function(response) {

  },
  nextStep: function() {
    this.$('.modal-body').hide();
    _gaq.push(['_trackEvent', 'registration', 'register-step-' + this.step ]);
    this.step++;
    this.$('.reg-body-' + this.step).show();
    this.setFormProgress();
    //this.$('#registration-form').attr('class', 'progress' + this.step);
    if (this.step == this.finalStep) {
      this.$('.registration-next').hide();
      this.$('.registration-done').show();
    } else if (this.step == 1) {
        this.$('input:first').focus();
    }
  },
  setFormProgress: function(){
    this.$('#registration-form').attr('class', 'progress' + this.step);
  },
  ohNoesPage: function() {
    this.$('.modal-body').hide();
    this.$('.reg-body-oh-noes').show();
  },
  notLoggedInPage: function() {
    this.$('.modal-body').hide();
    if (location.href.indexOf('editor') >= 0) {
      this.$('.registration-signin').show();
      this.$('.reg-body-no-login-editor').show();
    } else {
      this.$('.reg-body-no-login').show();
    }
  },
  submit: function(e) {
    e.preventDefault();
    if (typeof this.step !== 'undefined' && this.step > 0) {
        this.validateFields();
    }
    // move to the next page
    if (!this.hasErrors()) {
      if (this.step == this.registrationStep) {
        this.$('.registration-next').hide();
        this.$('.modal-footer .buttons-right .ajax-loader').show();
        $.withCSRF(function(csrf) {
          $.ajax({
            data: this.getRegistrationData(),
            dataType: 'json',
            url: this.postUrl,
            type: 'post',
            success: this.onSubmit,
            error: this.onError,
          });
        }.bind(this));
        return;
      }
      this.nextStep();
    }

  },
  getRegistrationData: function(){
    return {
      username: this.$('.username').val(),
      password: this.$('.password').val(),
      birth_month: this.$('.birthmonth').val(),
      birth_year: this.$('.birthyear').val(),
      gender: this.$('input[name="gender"]:checked').val() || this.$('#gender_other_text').val(),
      country: this.$('.country').val(),
      email: this.$('.email').val(),
      subscribe: this.$('input[name="subscribe"]').is(':checked'),
      is_robot: this.$('input[name="yesno"]:checked').length > 0,
      csrfmiddlewaretoken: csrf
    };
  },
  onSubmit: function(response) {
    this.$('.modal-footer .buttons-right .ajax-loader').hide();
    if (response[0].success) {
      this.username = response[0].username;
      this.user_id = response[0].user_id;
      this.accountCreated = true;
      if (response[0].logged_in) {
        this.nextStep();
      }
      else {
        this.step = -1;
        _gaq.push(['_trackEvent', 'registration', 'register-step-oh-noes-no-login']);
        this.notLoggedInPage();
      }
    } else {
      this.step = -1;
      _gaq.push(['_trackEvent', 'registration', 'register-step-oh-noes-no-success-' + response[0].msg]);
      this.ohNoesPage();
    }
  },
  onError: function(response) {
    this.$('.modal-footer .buttons-right .ajax-loader').hide();
     _gaq.push(['_trackEvent', 'registration', 'register-step-oh-noes-ajax-error']);
    this.ohNoesPage()
  },
  onLaunchRegistration: function (e) {
    if (window.frameElement) {
      e.preventDefault();
      return window.parent.postMessage("registration-relaunch", getOrigin());
    }
    launchRegistration(e);
  },
  onDownloadProject: function (e) {
    e.preventDefault();
    if (JSdownloadProject) return JSdownloadProject();
  },
  onShowLogin: function (e) {
    e.preventDefault();
    $('#login-dialog').modal('show');
  },
  dismiss: function(e) {
    if (window.frameElement) {
      return window.parent.postMessage("registration-done", getOrigin());
    }
    if (this.accountCreated) {
      if (location.href.indexOf('editor')<0) {
        location.reload(true);
      } else {
        Scratch.LoggedInUser.set({'username': this.username, 'id': this.user_id});
      }
    }
  },
});

