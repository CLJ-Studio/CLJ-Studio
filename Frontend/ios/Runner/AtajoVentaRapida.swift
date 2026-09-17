import AppIntents
import Foundation
import Security

enum CredencialesAtajoVentaRapida {
  private static let servicio = "com.cljstudio.umarket.atajo-venta-rapida"
  private static let claveAcceso = "access-token"
  private static let claveRenovacion = "refresh-token"
  private static let claveUsuario = "user-id"

  static var accessToken: String? { leer(claveAcceso) }
  static var refreshToken: String? { leer(claveRenovacion) }
  static var userId: String? { leer(claveUsuario) }

  static func actualizar(
    accessToken: String?,
    refreshToken: String?,
    userId: String?
  ) throws {
    guard let accessToken, !accessToken.isEmpty,
          let refreshToken, !refreshToken.isEmpty,
          let userId, !userId.isEmpty else {
      borrar(claveAcceso)
      borrar(claveRenovacion)
      borrar(claveUsuario)
      return
    }
    try guardar(accessToken, en: claveAcceso)
    try guardar(refreshToken, en: claveRenovacion)
    try guardar(userId, en: claveUsuario)
  }

  private static func leer(_ cuenta: String) -> String? {
    let consulta: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: servicio,
      kSecAttrAccount as String: cuenta,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var resultado: CFTypeRef?
    guard SecItemCopyMatching(consulta as CFDictionary, &resultado)
            == errSecSuccess,
          let datos = resultado as? Data else {
      return nil
    }
    return String(data: datos, encoding: .utf8)
  }

  private static func guardar(_ valor: String, en cuenta: String) throws {
    let datos = Data(valor.utf8)
    let consulta: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: servicio,
      kSecAttrAccount as String: cuenta,
    ]
    let cambios: [String: Any] = [kSecValueData as String: datos]
    let estado = SecItemUpdate(
      consulta as CFDictionary,
      cambios as CFDictionary
    )
    if estado == errSecItemNotFound {
      var nuevo = consulta
      nuevo[kSecValueData as String] = datos
      nuevo[kSecAttrAccessible as String] =
        kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      let alta = SecItemAdd(nuevo as CFDictionary, nil)
      guard alta == errSecSuccess else {
        throw ErrorAtajoVentaRapida.llavero
      }
    } else if estado != errSecSuccess {
      throw ErrorAtajoVentaRapida.llavero
    }
  }

  private static func borrar(_ cuenta: String) {
    let consulta: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: servicio,
      kSecAttrAccount as String: cuenta,
    ]
    SecItemDelete(consulta as CFDictionary)
  }
}

enum ErrorAtajoVentaRapida: LocalizedError {
  case sinSesion
  case sinProductos
  case stockInsuficiente
  case productoNoDisponible
  case respuestaInvalida
  case servidor(String)
  case llavero

  var errorDescription: String? {
    switch self {
    case .sinSesion:
      return "Abre U market e inicia sesión una vez antes de usar este atajo."
    case .sinProductos:
      return "Tu local no tiene productos disponibles con stock."
    case .stockInsuficiente:
      return "No queda suficiente stock de ese producto."
    case .productoNoDisponible:
      return "Ese producto ya no está disponible."
    case .respuestaInvalida:
      return "U market recibió una respuesta inesperada."
    case .servidor(let mensaje):
      return mensaje
    case .llavero:
      return "No se pudo guardar de forma segura la sesión del atajo."
    }
  }
}

private struct FilaProductoVentaRapida: Decodable {
  let id: String
  let name: String
  let emoji: String
  let stock: Int
  let price: Double
}

private struct RespuestaRenovacion: Decodable {
  let accessToken: String
  let refreshToken: String
  let user: UsuarioRenovado

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case user
  }
}

private struct UsuarioRenovado: Decodable {
  let id: String
}

private struct RespuestaErrorServidor: Decodable {
  let message: String?
}

@available(iOS 16.0, *)
private actor ClienteAtajoVentaRapida {
  static let compartido = ClienteAtajoVentaRapida()

  private let urlBase = URL(
    string: "https://tujqaxohgpeoxxezbzzp.supabase.co"
  )!
  private let llavePublica =
    "sb_publishable_HUgvzw_cOV4vS8WUkzXX2Q_pTurdJar"

  func productos() async throws -> [ProductoAtajoVentaRapida] {
    let datos = try await llamarRPC(
      "list_quick_sale_products",
      cuerpo: Data("{}".utf8)
    )
    let filas = try JSONDecoder().decode(
      [FilaProductoVentaRapida].self,
      from: datos
    )
    return filas.map {
      ProductoAtajoVentaRapida(
        id: $0.id,
        nombre: $0.name,
        emoji: $0.emoji,
        stock: $0.stock,
        precio: $0.price
      )
    }
  }

  func registrar(productoId: String, cantidad: Int) async throws {
    let cuerpo = try JSONSerialization.data(withJSONObject: [
      "p_product_id": productoId,
      "p_quantity": cantidad,
    ])
    _ = try await llamarRPC("register_quick_sale", cuerpo: cuerpo)
  }

  private func llamarRPC(
    _ funcion: String,
    cuerpo: Data,
    reintentar: Bool = true
  ) async throws -> Data {
    guard let token = CredencialesAtajoVentaRapida.accessToken else {
      throw ErrorAtajoVentaRapida.sinSesion
    }
    var solicitud = URLRequest(
      url: urlBase.appendingPathComponent("rest/v1/rpc/\(funcion)")
    )
    solicitud.httpMethod = "POST"
    solicitud.httpBody = cuerpo
    solicitud.setValue("application/json", forHTTPHeaderField: "Content-Type")
    solicitud.setValue(llavePublica, forHTTPHeaderField: "apikey")
    solicitud.setValue(
      "Bearer \(token)",
      forHTTPHeaderField: "Authorization"
    )

    let (datos, respuesta) = try await URLSession.shared.data(for: solicitud)
    guard let http = respuesta as? HTTPURLResponse else {
      throw ErrorAtajoVentaRapida.respuestaInvalida
    }
    if http.statusCode == 401, reintentar {
      try await renovarSesion()
      return try await llamarRPC(funcion, cuerpo: cuerpo, reintentar: false)
    }
    guard (200..<300).contains(http.statusCode) else {
      throw traducirError(datos)
    }
    return datos
  }

  private func renovarSesion() async throws {
    guard let token = CredencialesAtajoVentaRapida.refreshToken else {
      throw ErrorAtajoVentaRapida.sinSesion
    }
    let url = urlBase.appendingPathComponent("auth/v1/token")
      .appending(queryItems: [URLQueryItem(
        name: "grant_type",
        value: "refresh_token"
      )])
    var solicitud = URLRequest(url: url)
    solicitud.httpMethod = "POST"
    solicitud.httpBody = try JSONSerialization.data(withJSONObject: [
      "refresh_token": token,
    ])
    solicitud.setValue("application/json", forHTTPHeaderField: "Content-Type")
    solicitud.setValue(llavePublica, forHTTPHeaderField: "apikey")

    let (datos, respuesta) = try await URLSession.shared.data(for: solicitud)
    guard let http = respuesta as? HTTPURLResponse,
          (200..<300).contains(http.statusCode) else {
      throw ErrorAtajoVentaRapida.sinSesion
    }
    let sesion = try JSONDecoder().decode(RespuestaRenovacion.self, from: datos)
    try CredencialesAtajoVentaRapida.actualizar(
      accessToken: sesion.accessToken,
      refreshToken: sesion.refreshToken,
      userId: sesion.user.id
    )
  }

  private func traducirError(_ datos: Data) -> Error {
    let mensaje = (
      try? JSONDecoder().decode(RespuestaErrorServidor.self, from: datos)
    )?.message ?? "No se pudo registrar la venta."
    if mensaje.contains("STOCK_INSUFICIENTE") {
      return ErrorAtajoVentaRapida.stockInsuficiente
    }
    if mensaje.contains("PRODUCTO_NO_DISPONIBLE") ||
       mensaje.contains("PRODUCTO_INEXISTENTE") {
      return ErrorAtajoVentaRapida.productoNoDisponible
    }
    if mensaje.contains("SESION_REQUERIDA") ||
       mensaje.contains("JWT") {
      return ErrorAtajoVentaRapida.sinSesion
    }
    return ErrorAtajoVentaRapida.servidor(mensaje)
  }
}

@available(iOS 16.0, *)
struct ProductoAtajoVentaRapida: AppEntity, Hashable {
  static var typeDisplayRepresentation = TypeDisplayRepresentation(
    name: "Producto"
  )
  static var defaultQuery = ConsultaProductosAtajoVentaRapida()

  let id: String
  let nombre: String
  let emoji: String
  let stock: Int
  let precio: Double

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(emoji) \(nombre)",
      subtitle: "\(stock) disponibles · Bs \(precio, format: .number.precision(.fractionLength(2)))"
    )
  }
}

@available(iOS 16.0, *)
struct ConsultaProductosAtajoVentaRapida: EntityStringQuery {
  func entities(
    for identifiers: [ProductoAtajoVentaRapida.ID]
  ) async throws -> [ProductoAtajoVentaRapida] {
    let productos = try await ClienteAtajoVentaRapida.compartido.productos()
    let buscados = Set(identifiers)
    return productos.filter { buscados.contains($0.id) }
  }

  func entities(
    matching string: String
  ) async throws -> [ProductoAtajoVentaRapida] {
    let productos = try await suggestedEntities()
    guard !string.isEmpty else { return productos }
    return productos.filter {
      $0.nombre.localizedCaseInsensitiveContains(string)
    }
  }

  func suggestedEntities() async throws -> [ProductoAtajoVentaRapida] {
    let productos = try await ClienteAtajoVentaRapida.compartido.productos()
    guard !productos.isEmpty else {
      throw ErrorAtajoVentaRapida.sinProductos
    }
    return productos
  }
}

@available(iOS 16.0, *)
enum CantidadAtajoVentaRapida: String, AppEnum {
  case uno
  case dos
  case tres

  static var typeDisplayRepresentation = TypeDisplayRepresentation(
    name: "Cantidad"
  )
  static var caseDisplayRepresentations: [
    CantidadAtajoVentaRapida: DisplayRepresentation
  ] = [
    .uno: "1",
    .dos: "2",
    .tres: "3",
  ]

  var valor: Int {
    switch self {
    case .uno: return 1
    case .dos: return 2
    case .tres: return 3
    }
  }
}

@available(iOS 16.0, *)
struct RegistrarVentaRapidaIntent: AppIntent {
  static var title: LocalizedStringResource = "Registrar venta rápida"
  static var description = IntentDescription(
    "Elige un producto y una cantidad. U market guarda la venta y descuenta el stock sin abrir la app."
  )
  static var openAppWhenRun = false

  @Parameter(title: "Producto")
  var producto: ProductoAtajoVentaRapida

  @Parameter(title: "Cantidad", default: .uno)
  var cantidad: CantidadAtajoVentaRapida

  static var parameterSummary: some ParameterSummary {
    Summary("Vender \(\.$cantidad) de \(\.$producto)")
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    try await ClienteAtajoVentaRapida.compartido.registrar(
      productoId: producto.id,
      cantidad: cantidad.valor
    )
    return .result(
      dialog: "Venta registrada y stock actualizado."
    )
  }
}

@available(iOS 16.0, *)
struct AtajosUMarket: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: RegistrarVentaRapidaIntent(),
      phrases: [
        "Registrar una venta en \(.applicationName)",
        "Venta rápida en \(.applicationName)",
      ],
      shortTitle: "Venta rápida",
      systemImageName: "bolt.cart.fill"
    )
  }
}
