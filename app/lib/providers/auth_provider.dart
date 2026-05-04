import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _usuario;
  bool     _cargando = false;
  String?  _error;

  Usuario? get usuario   => _usuario;
  bool     get cargando  => _cargando;
  String?  get error     => _error;
  bool     get logueado  => _usuario != null;

  // Verificar si hay sesión guardada al arrancar
  Future<void> verificarSesion() async {
    _usuario = await AuthService.getUsuarioGuardado();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _cargando = true;
    _error    = null;
    notifyListeners();

    try {
      final data = await AuthService.login(email, password);
      _usuario   = Usuario.fromJson(data['usuario']);
      _cargando  = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error    = e.toString().replaceAll('Exception: ', '');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registro(String email, String password, String nombre) async {
    _cargando = true;
    _error    = null;
    notifyListeners();

    try {
      final data = await AuthService.registro(email, password, nombre);
      _usuario   = Usuario.fromJson(data['usuario']);
      _cargando  = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error    = e.toString().replaceAll('Exception: ', '');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarPerfil(String nombre, String telefono) async {
    _cargando = true;
    _error    = null;
    notifyListeners();

    try {
      final data = await AuthService.actualizarPerfil(nombre, telefono);
      _usuario   = Usuario.fromJson(data);
      _cargando  = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error    = e.toString().replaceAll('Exception: ', '');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _usuario = null;
    notifyListeners();
  }
}