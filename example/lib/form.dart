import 'dart:async';

import 'package:flutter/material.dart';

class ValidationResult {
  ValidationResult(
      {this.message = "",
      this.property = "",
      this.keyword = "",
      this.dataPath = "",
      this.schemaPath = "",
      this.params = const {}})
      : super();
  late final String? message;
  late final String? property;
  late final String? keyword;
  late final String? dataPath;
  late final String? schemaPath;
  late final Map<String, dynamic> params;

  static ValidationResult fromJson(Map<String, dynamic> map) {
    return ValidationResult(
        message: map['message'],
        property: map['property'],
        dataPath: map['dataPath'],
        schemaPath: map['schemaMap'],
        keyword: map['keyword'],
        params: map['params'] ?? {});
  }

  static List<ValidationResult> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((el) => fromJson(el)).toList();
  }
}

// ignore: constant_identifier_names
enum FormWidgetOperation { New, Edit }

class FormWidget extends StatefulWidget {
  FormWidget({
    required this.operation,
    required this.formWidgetKey,
    required this.formKey,
    required this.validateFunction,
    required this.fields,
  }) : super(key: formWidgetKey);

  final FormWidgetOperation operation;
  final List<String> fields;
  final GlobalKey<FormState> formKey;
  final _focusScopeNode = FocusScopeNode();

  final GlobalKey<FormWidgetState> formWidgetKey;
  final List<ValidationResult> Function(
      String key, String value, Map<String, String> form) validateFunction;

  @override
  FormWidgetState createState() => FormWidgetState();
}

class FormWidgetState extends State<FormWidget> {
  final Map<String, String> _fieldValues = {};
  final Map<String, String> _savedValues = {};
  final Map<String, GlobalKey<FormFieldState>> _fieldsStates = {};
  final Map<String, List<ValidationResult>> _errorsMap = {};
  final Map<String, Debouncer> _fieldsDebounces = {};
  final Map<String, FocusNode> _fieldsFocusNodes = {};

  // setErrorAsync(String field, List<ValidationResult> errors) {
  //   _errorsMap[field] = errors;
  //   _stateFromAsync[field] = true;
  //   _fieldsStates[field].currentState?.validate();
  // }

  _validatorFor(String field) {
    return (String? value) {
      String actualValue = _savedValues[field] ?? '';
      _fieldValues[field] = actualValue;
      _errorsMap[field] =
          widget.validateFunction(field, actualValue, _fieldValues);
      return (_errorsMap[field] ?? []).isNotEmpty ? 'Campo inválido' : null;
    };
  }

  _onSavedFor(String field) {
    return (value) {
      _savedValues[field] = value;
    };
  }

  @override
  void initState() {
    super.initState();
    for (var fieldName in widget.fields) {
      _fieldsStates[fieldName] = GlobalKey();
      _fieldsDebounces[fieldName] = Debouncer(milliseconds: 200);
      _fieldsFocusNodes[fieldName] = FocusNode();
    }
  }

  bool shouldFocus(String fieldName) {
    return widget.fields.first == fieldName &&
        widget.operation == FormWidgetOperation.New;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FocusScope(
        node: widget._focusScopeNode,
        child: Form(
            key: widget.formKey,
            autovalidateMode: AutovalidateMode.always,
            child: Column(
              children: widget.fields
                  .map(
                    (field) => Padding(
                      padding: const EdgeInsets.fromLTRB(4.0, 4, 4, 8),
                      child: getInputWidgetForField(field),
                    ),
                  )
                  .toList(),
            )),
      ),
    );
  }

  Widget getInputWidgetForField(String field) {
    if (field == "worker" || field == "student") {
      return getCheckboxField(field);
    } else {
      return getTextFormField(field);
    }
  }

  Widget getCheckboxField(String field) {
    return CheckboxListTile(
      value: _fieldValues[field] == "true",
      onChanged: (value) {
        setState(() {
          _fieldValues[field] = value.toString();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.formKey.currentState!.validate();
          });
        });
      },
      title: Text(field),
      subtitle: const Text(
        'Requerido',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget getTextFormField(String field) {
    return TextFormField(
        autofocus: shouldFocus(field),
        focusNode: _fieldsFocusNodes[field],
        textInputAction: widget.fields.last == field
            ? TextInputAction.done
            : TextInputAction.next,
        key: _fieldsStates[field],
        decoration: InputDecoration(
          labelText: field,
          suffixIcon: (field == 'age')
              ? IconButton(
                  autofocus: false,
                  icon: const Icon(
                    Icons.warning,
                    color: Colors.orange,
                  ),
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      WidgetsBinding.instance.focusManager.primaryFocus
                          ?.unfocus();
                      FocusScope.of(context).requestFocus(FocusNode());

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Aviso'),
                          content: Text(
                            'Aviso no campo $field',
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ).then((_) {
                        FocusScope.of(context).requestFocus(
                          _fieldsFocusNodes[field],
                        );
                      });
                    });
                  },
                )
              : null,
          //floatingLabelBehavior: FloatingLabelBehavior.always,
          border: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.secondary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.fromLTRB(8, 1, 8, 2),
          alignLabelWithHint: true,
        ),
        validator: _validatorFor(field),
        // onChanged: (value) {
        //   addPostFrameCallback
        //   _fieldsStates[field].currentState.validate();
        // },
        onEditingComplete: () {
          _fieldsStates[field]?.currentState!.validate();
          if (widget.fields.last == field) {
            widget._focusScopeNode.unfocus();
          } else {
            widget._focusScopeNode.nextFocus();
          }
        },
        onChanged: _onSavedFor(field),
        onSaved: _onSavedFor(field));
  }
}

class Debouncer {
  late final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({this.milliseconds = 0});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
