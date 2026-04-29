import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = '';
  String _result = '0';

  final Parser _parser = Parser();

  _CalculatorPageState() {
    _parser.addFunction('lg', (List<double> args) {
      if (args[0] <= 0) return double.nan;
      return math.log(args[0]) / math.ln10;
    });
  }

  void _onTap(String text) {
    setState(() {
      switch (text) {
        case 'C':
          _expression = '';
          _result = '0';
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          _evaluate();
        case '=':
          _evaluateFinal();
        case 'xʸ':
          _expression += '^(';
          _evaluate();
        case '√':
          _expression += 'sqrt(';
          _evaluate();
        case 'π':
          _expression += 'pi';
          _evaluate();
        case 'e':
          _expression += 'e^';
          _evaluate();
        case '×':
          _expression += '*';
          _evaluate();
        case '÷':
          _expression += '/';
          _evaluate();
        default:
          _expression += text;
          _evaluate();
      }
    });
  }

  void _evaluate() {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }
    try {
      final Expression exp = _parser.parse(_expression);
      final ContextModel cm = ContextModel()
        ..bindVariableName('pi', Number(math.pi));
      final double val = exp.evaluate(EvaluationType.REAL, cm);
      _result = _format(val);
    } catch (_) {
      _result = '';
    }
  }

  void _evaluateFinal() {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }
    try {
      final Expression exp = _parser.parse(_expression);
      final ContextModel cm = ContextModel()
        ..bindVariableName('pi', Number(math.pi));
      final double val = exp.evaluate(EvaluationType.REAL, cm);
      _result = _format(val);
      _expression = _format(val);
    } catch (_) {
      _result = 'Error';
      _expression = '';
    }
  }

  String _format(double value) {
    if (value.isNaN) return 'Error';
    if (value.isInfinite) return value > 0 ? '∞' : '-∞';
    if (value == value.truncateToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    String s = value.toStringAsFixed(10);
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    if (s.length > 15) {
      s = value.toStringAsExponential(6);
    }
    return s;
  }

  Widget _btn(String text, {Color? bg, Color? fg}) {
    final Color bgColor = bg ?? Colors.grey.shade200;
    final Color fgColor = fg ?? Colors.black87;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _onTap(text),
            child: Container(
              alignment: Alignment.center,
              height: 48,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: text.length > 2 ? 15 : 20,
                  fontWeight: FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('科学计算器'),
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
      ),
      body: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _expression.isEmpty ? ' ' : _expression,
                    style: TextStyle(fontSize: 22, color: Colors.grey.shade600),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _result,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Row(children: <Widget>[
                    _btn('C', bg: Colors.red.shade100, fg: Colors.red),
                    _btn('⌫'),
                    _btn('('),
                    _btn(')', bg: Colors.blue.shade100, fg: Colors.blue.shade800),
                  ]),
                  Row(children: <Widget>[
                    _btn('sin'),
                    _btn('cos'),
                    _btn('tan'),
                    _btn('÷', bg: Colors.blue.shade100, fg: Colors.blue.shade800),
                  ]),
                  Row(children: <Widget>[
                    _btn('lg'),
                    _btn('ln'),
                    _btn('xʸ'),
                    _btn('√', bg: Colors.blue.shade100, fg: Colors.blue.shade800),
                  ]),
                  Row(children: <Widget>[
                    _btn('7'),
                    _btn('8'),
                    _btn('9'),
                    _btn('×', bg: Colors.blue.shade100, fg: Colors.blue.shade800),
                  ]),
                  Row(children: <Widget>[
                    _btn('4'),
                    _btn('5'),
                    _btn('6'),
                    _btn('-', bg: Colors.blue.shade100, fg: Colors.blue.shade800),
                  ]),
                  Row(children: <Widget>[
                    _btn('1'),
                    _btn('2'),
                    _btn('3'),
                    _btn('+', bg: Colors.blue.shade100, fg: Colors.blue.shade800),
                  ]),
                  Row(children: <Widget>[
                    _btn('π'),
                    _btn('e'),
                    _btn('.'),
                    _btn('=', bg: Colors.blue, fg: Colors.white),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
