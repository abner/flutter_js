import 'dart:async';

import 'package:flutter/material.dart';

class ValidationResult {
  ValidationResult(
      {this.message = "",
      this.property = "",
      this.keyword = "",
      this.dataPath = "",
      this.schemaPath = ""})
      : super();
  final String message;
  final String property;
  final String keyword;
  final String dataPath;
  final String schemaPath;

  static ValidationResult fromJson(Map<String, dynamic> map) {
    return ValidationResult(
        message: map['message'],
        property: map['property'],
        dataPath: map['dataPath'],
        schemaPath: map['schemaMap'],
        keyword: map['keyword']);
  }

  static List<ValidationResult> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((el) => fromJson(el)).toList();
  }
}

class FormWidget extends StatefulWidget {
  FormWidget({
    @required this.formWidgetKey,
    @required this.formKey,
    @required this.validateFunction,
    @required this.fields,
  }) : super(key: formWidgetKey);

  final List<String> fields;
  final GlobalKey<FormState> formKey;

  final GlobalKey<FormWidgetState> formWidgetKey;
  final List<ValidationResult> Function(
      String key, String value, Map<String, String> form) validateFunction;

  @override
  FormWidgetState createState() => FormWidgetState();
}

class FormWidgetState extends State<FormWidget> {
  Map<String, String> _fieldValues = {};
  Map<String, String> _savedValues = {};
  Map<String, GlobalKey<FormFieldState>> _fieldsStates = {};
  Map<String, List<ValidationResult>> _errorsMap = {};
  Map<String, bool> _stateFromAsync = {};
  Map<String, Debouncer> _fieldsDebounces = {};

  setErrorAsync(String field, List<ValidationResult> errors) {
    _errorsMap[field] = errors;
    _stateFromAsync[field] = true;
    _fieldsStates[field].currentState?.validate();
  }

  _validatorFor(String field) {
    return (String value) {
      if (_stateFromAsync[field] ?? false) {
        _stateFromAsync[field] = false;
        return _errorsMap[field].length > 0 ? 'Some Error from Ajv' : null;
      }
      _savedValues[field] = null;
      _fieldValues[field] = value;
      _errorsMap[field] =
          widget.validateFunction(field, value, _fieldValues) ?? [];
      return _errorsMap[field].length > 0 ? 'Campo inválido' : null;
    };
  }

  _onSavedFor(String field) {
    return (value) {
      _savedValues[field] = value;
    };
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.fields.forEach((fieldName) {
      _fieldsStates[fieldName] = GlobalKey();
      _fieldsDebounces[fieldName] = Debouncer(milliseconds: 500);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
            key: widget.formKey,
            autovalidate: false,
            child: Column(
              children: widget.fields
                  .map(
                    (field) => Padding(
                      padding: const EdgeInsets.fromLTRB(4.0, 4, 4, 8),
                      child: TextFormField(
                          key: _fieldsStates[field],
                          decoration: InputDecoration(
                              labelText: field,
                              //border: InputBorder.none,
                              suffixIcon: (field == 'age')
                                  ? GestureDetector(
                                      child: Icon(
                                        Icons.warning,
                                        color: Colors.orange,
                                      ),
                                      onTap: () {
//                                  Scaffold.of(context).removeCurrentSnackBar();
//                                  Scaffold.of(context).showSnackBar(SnackBar(
//                                      behavior: SnackBarBehavior.fixed,
//                                      content:
//                                          Text('Aviso no campo $field!!!!')));
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Aviso'),
                                            content:
                                                Text('Aviso no campo $field'),
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).accentColor,
                                    width: 1.5),
                              ),
                              contentPadding: EdgeInsets.fromLTRB(8, 1, 8, 2),
                              alignLabelWithHint: true,
//                            focusedBorder: OutlineInputBorder(
//                              borderSide: BorderSide(
//                                  color: Theme.of(context).accentColor, width: 1.5),
//                            ),
//                            errorBorder: OutlineInputBorder(
//                              borderRadius: BorderRadius.circular(3.1),
//                              borderSide: BorderSide(
//                                  color: Theme.of(context).colorScheme.onError, width: 1.5),
//                            ),
//                            enabledBorder: OutlineInputBorder(
//                              borderSide: BorderSide(
//                                  color: Theme.of(context).primaryColor,
//                                  width: 1.0),
//                            ),
                              ),
                          validator: _validatorFor(field),
                          onChanged: (value) {
                            _fieldsDebounces[field].run(() =>
                                _fieldsStates[field].currentState.validate());
                          },
                          onEditingComplete: () =>
                              _fieldsStates[field].currentState.validate(),
                          onSaved: _onSavedFor(field)),
                    ),
                  )
                  .toList(),
            )),
      ),
    );
  }
}

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer _timer;

  Debouncer({this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer.cancel();
    }

    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
