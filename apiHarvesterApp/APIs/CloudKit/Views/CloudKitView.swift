import SwiftUI
public extension UIColor {
  convenience init<T>(rgbValue: T, alpha: CGFloat = 1) where T: BinaryInteger {
    guard rgbValue > 0 else {
      self.init(red: 0, green: 0, blue: 0, alpha: alpha)
      return
    }

    guard rgbValue < 0xFFFFFF else {
      self.init(red: 1, green: 1, blue: 1, alpha: alpha)
      return
    }

    let red: CGFloat = CGFloat((rgbValue & 0xFF0000) >> 16) / 0xFF
    let green: CGFloat = CGFloat((rgbValue & 0x00FF00) >> 8) / 0xFF
    let blue: CGFloat = CGFloat(rgbValue & 0x0000FF) / 0xFF

    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}

struct GridStack<Content: View>: View {
  let rows: Int
  let columns: Int
  let content: (Int, Int) -> Content

  public var body: some View {
    VStack {
      ForEach(0 ..< rows, id: \.self) { row in
        HStack {
          ForEach(0 ..< self.columns, id: \.self) { column in
            self.content(row, column)
          }
        }
      }
    }
  }

  init(rows: Int, columns: Int, @ViewBuilder content: @escaping (Int, Int) -> Content) {
    self.rows = rows
    self.columns = columns
    self.content = content
  }
}

struct CloudKitView: View {
  @EnvironmentObject var colorsObject: CloudKitObject
  @State var color: Int?

  let rows = 6
  let columns = 3

  let colors = (0 ... (6 * 3)).map { _ in
    Int.random(in: 0 ... 0xFFFFFF)
  }

  public var body: some View {
    GridStack(rows: self.rows, columns: self.columns) { row, col in
      Rectangle().foregroundColor(
        Color(
          UIColor(rgbValue: self.colors[row * 3 + col])
        )
      )
    }
  }
}

struct CloudKitView_Previews: PreviewProvider {
  public static var previews: some View {
    CloudKitView()
  }
}
