import 'package:flutter/material.dart';

class LoginController {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();

  bool tentarLogin() {
    if (formKey.currentState!.validate()) {
      print("=== DADOS DO FORMULÁRIO ===");
      print("Nome: ${nomeController.text}");
      print("Telefone: ${telefoneController.text}");
      print("===========================");

      return true;
    }
    return false;
  }

  //fazer dispose dps de usar pra n gerar problema na memoria
  void limparMemoria() {
    nomeController.dispose();
    telefoneController.dispose();
  }
}
