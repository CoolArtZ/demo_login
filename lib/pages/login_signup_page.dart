import 'package:flutter/material.dart';
import 'package:flutter_login_demo/services/authentication.dart';

class LoginSignUpPage extends StatefulWidget {
  LoginSignUpPage({this.auth, this.onSignedIn});

  final BaseAuth auth;
  final VoidCallback onSignedIn;

  @override
  State<StatefulWidget> createState() => new _LoginSignUpPageState();
}

enum FormMode { LOGIN, SIGNUP, RESET }

class _LoginSignUpPageState extends State<LoginSignUpPage> {
  final _formKey = new GlobalKey<FormState>();

  // Set text focus
  var _emailController = TextEditingController();
  var _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String _email;
  String _password;
  String _errorMessage;

  // Initial form is login form
  FormMode _formMode = FormMode.LOGIN;
  bool _isIos;
  bool _isLoading;

  // Check if form is valid before perform login or signup
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or signup
  void _validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (_validateAndSave()) {
      String userId = "";
      try {
        if (_formMode == FormMode.LOGIN) {
          userId = await widget.auth.signIn(_email, _password);
          print('Signed in: $userId');
        } else if (_formMode == FormMode.RESET) {
          await widget.auth.resetPassword(_email);
          _showResetEmailSentDialog();
        } else {
          userId = await widget.auth.signUp(_email, _password);
          widget.auth.sendEmailVerification();
          _showVerifyEmailSentDialog();
          print('Signed up user: $userId');
        }
        setState(() {
          _isLoading = false;
        });

        if (userId != null &&
            userId.length > 0 &&
            _formMode == FormMode.LOGIN) {
          widget.onSignedIn();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          if (_isIos) {
            _errorMessage = e.details;
          } else
            _errorMessage = e.message;
        });
      }
    }
  }

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    super.initState();
  }

  void _changeFormToSignUp() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.LOGIN;
    });
  }

  void _changeFormToReset() {
    _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.RESET;
    });
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Flutter login demo'),
        ),
        body: Stack(
          children: <Widget>[
            _showBody(),
            _showCircularProgress(),
          ],
        ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content:
              new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                _changeFormToLogin();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showResetEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Password Reset"),
          content: new Text(" Reset instruction has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                _changeFormToLogin();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _showBody() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              _showLogo(),
              _showEmailInput(),
              _showPasswordInput(),
              _showPrimaryButton(),
              _showSecondaryButton(),
              _showTertiaryButton(),
              _showErrorMessage(),
            ],
          ),
        ));
  }

  Widget _showLogo() {
    return new Hero(
      tag: 'hero',
      child: FlutterLogo(size: 100.0),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
      child: new TextFormField(
        controller: _emailController,
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        focusNode: _emailFocus,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) {
          if (value.isEmpty) {
            setState(() {
              _isLoading = false;
            });
            return 'Email can\'t be empty';
          }
        },
        onSaved: (value) => _email = value,
        onFieldSubmitted: (term) {
          if (_formMode == FormMode.RESET) {
            _emailFocus.unfocus();
            _validateAndSubmit();
          }
          else {
            _fieldFocusChange(context, _emailFocus, _passwordFocus);
          }
        },
      ),
    );
  }

  Widget _showPasswordForm() {
    if (_formMode == FormMode.LOGIN || _formMode == FormMode.SIGNUP) {
      return new TextFormField(
          controller: _passwordController,
          maxLines: 1,
          obscureText: true,
          autofocus: false,
          focusNode: _passwordFocus,
          decoration: new InputDecoration(
              hintText: 'Password',
              icon: new Icon(
                Icons.lock,
                color: Colors.grey,
              )),
          validator: (value) {
            if (value.isEmpty) {
              setState(() {
                _isLoading = false;
              });
              return 'Email can\'t be empty';
            }
          },
          onSaved: (value) => _password = value,
          onFieldSubmitted: (value) {
            _passwordFocus.unfocus();
            _validateAndSubmit();
          },
      );
    }
  }

  Widget _showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: _showPasswordForm(),
      /*child: new TextFormField(
        controller: _passwordController,
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        focusNode: _passwordFocus,
        decoration: new InputDecoration(
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) {
          if (value.isEmpty) {
            setState(() {
              _isLoading = false;
            });
            return 'Email can\'t be empty';
          }
        },
        onSaved: (value) => _password = value,
        onFieldSubmitted: (value) {
          _passwordFocus.unfocus();
          _validateAndSubmit();
        },
      ),*/
    );
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  Widget _primaryButtonText() {
    if (_formMode == FormMode.LOGIN) {
      return new Text('Login',
          style: new TextStyle(fontSize: 20.0, color: Colors.white));
    } else if (_formMode == FormMode.SIGNUP) {
      return new Text('Create account',
          style: new TextStyle(fontSize: 20.0, color: Colors.white));
    }
    return new Text('Reset Password',
        style: new TextStyle(fontSize: 20.0, color: Colors.white));
  }

  Widget _showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: _primaryButtonText(),
            /*child: _formMode == FormMode.LOGIN
                ? new Text('Login',
                style: new TextStyle(fontSize: 20.0, color: Colors.white))
                : new Text('Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),*/
            onPressed: _validateAndSubmit,
          ),
        ));
  }

  Widget _showSecondaryButton() {
    return new FlatButton(
      child: _formMode == FormMode.LOGIN
          ? new Text('Create an account',
              style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300))
          : new Text('Have an account? Sign in',
              style:
                  new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
      onPressed: _formMode == FormMode.LOGIN
          ? _changeFormToSignUp
          : _changeFormToLogin,
    );
  }

  Widget _showTertiaryButton() {
    return new FlatButton(
      child: _formMode == FormMode.LOGIN
          ? new Text('Forgot password',
              style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300))
          : null,
      onPressed: _formMode == FormMode.LOGIN ? _changeFormToReset : null,
    );
  }

  Widget _showErrorMessage() {
    if (_errorMessage != null && _errorMessage.length > 0) {
      return new Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }
}
