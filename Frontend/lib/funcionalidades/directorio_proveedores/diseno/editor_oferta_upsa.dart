import 'package:flutter/material.dart';

import '../datos/repositorio_directorio.dart';
import '../modelos/proveedor_upsa.dart';

/// Si el negocio aparece en el directorio de la UPSA, y que le ofrece.
///
/// Va debajo de los datos del negocio. No aparece si no hay negocio formal
/// ni mientras la migracion de las cuentas UPSA no este aplicada: sin las
/// columnas no habria donde guardarlo.
class EditorOfertaUpsa extends StatefulWidget {
  const EditorOfertaUpsa({
    this.repositorio = const RepositorioDirectorio(),
    super.key,
  });

  final RepositorioDirectorio repositorio;

  @override
  State<EditorOfertaUpsa> createState() => _EditorOfertaUpsaState();
}

class _EditorOfertaUpsaState extends State<EditorOfertaUpsa> {
  final _texto = TextEditingController();
  OfertaUpsa? _oferta;
  bool _activa = false;
  bool _guardando = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final oferta = await widget.repositorio.cargarOfertaPropia();
      if (!mounted || oferta == null) return;
      setState(() {
        _oferta = oferta;
        _activa = oferta.activa;
        _texto.text = oferta.texto;
      });
    } catch (_) {
      // Sin la opcion: el resto del negocio se sigue editando igual.
    }
  }

  Future<void> _guardar() async {
    final oferta = _oferta;
    if (oferta == null) return;
    setState(() {
      _guardando = true;
      _aviso = null;
    });
    try {
      await widget.repositorio.guardarOfertaPropia(
        OfertaUpsa(
          localId: oferta.localId,
          activa: _activa,
          texto: _texto.text,
        ),
      );
      if (mounted) {
        setState(
          () => _aviso = _activa
              ? 'Listo: tu negocio aparece en el directorio de la UPSA.'
              : 'Listo: tu negocio ya no aparece en el directorio.',
        );
      }
    } catch (fallo) {
      if (!mounted) return;
      setState(
        () => _aviso = fallo.toString().contains('CONTENIDO_NO_PERMITIDO')
            ? 'Revisa lo que escribiste: contiene texto no permitido.'
            : 'No se pudo guardar. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_oferta == null) return const SizedBox.shrink();
    final apagado = Theme.of(context).textTheme.bodyMedium?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 40),
        Row(
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 19,
              color: Color(0xFF474646),
            ),
            const SizedBox(width: 8),
            Text(
              'Directorio de la UPSA',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'La UPSA busca proveedores entre los emprendimientos de su '
          'comunidad. Si lo activas, su personal ve tu negocio, lo que le '
          'ofreces y tu WhatsApp para contactarte.',
          style: TextStyle(fontSize: 12, color: apagado, height: 1.4),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _activa,
          onChanged: _guardando
              ? null
              : (valor) => setState(() {
                  _activa = valor;
                  _aviso = null;
                }),
          title: const Text(
            'Aparecer en el directorio de la UPSA',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (_activa) ...[
          const SizedBox(height: 4),
          TextField(
            controller: _texto,
            maxLength: 280,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: '¿Qué le ofreces a la UPSA?',
              hintText:
                  'Ej.: catering para eventos, impresiones, diseño de logos',
              alignLabelWithHint: true,
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _guardando ? null : _guardar,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF474646),
              shape: const StadiumBorder(),
            ),
            child: Text(_guardando ? 'Guardando…' : 'Guardar'),
          ),
        ),
        if (_aviso case final String aviso) ...[
          const SizedBox(height: 8),
          Text(aviso, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
