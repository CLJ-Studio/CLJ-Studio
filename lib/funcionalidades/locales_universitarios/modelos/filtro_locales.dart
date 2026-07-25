/// Describe filtros que podrán enviarse al backend.
class FiltroLocales {
  const FiltroLocales({this.consulta = '', this.categoriaId = 'todas'});
  final String consulta;
  final String categoriaId;
}
