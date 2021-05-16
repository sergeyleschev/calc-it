
func evalArithmeticExpression(_ input: String) -> Double {
    var opPrecedence = ExpressionBuilder.sharedInstance

    for token in input.components(separatedBy: .whitespaces) {
        let number = Double(token)
        if (number != nil) {
            opPrecedence.addOperand(number!)
        } else {
            switch token {
            case "(": opPrecedence.addOpenBracket()
            case ")": opPrecedence.addCloseBracket()
            case "+": opPrecedence.addOperator(.add)
            case "-": opPrecedence.addOperator(.subtract)
            case "*": opPrecedence.addOperator(.multiply)
            case "/": opPrecedence.addOperator(.divide)
            case "^": opPrecedence.addOperator(.power)
            default: break
            }
        }
    }
    
    let expr : [Token] = opPrecedence.build()
    let rpn = reversePolishNotation(expr)
    let result = evalRPN(rpn)
    return result
}


// --------------

public class ExpressionBuilder {	
  static var sharedInstance : ExpressionBuilder = { ExpressionBuilder() }()
  public var expression = [Token]()

  public func addOperator(_ operatorType: OperatorType) -> ExpressionBuilder {
    expression.append(Token(operatorType: operatorType))
    return self
  }

  public func addOperand(_ operand: Double) -> ExpressionBuilder {
    expression.append(Token(operand: operand))
    return self
  }

  public func addOpenBracket() -> ExpressionBuilder {
    expression.append(Token(tokenType: .openBracket))
    return self
  }

  public func addCloseBracket() -> ExpressionBuilder {
    expression.append(Token(tokenType: .closeBracket))
    return self
  }

  public func build() -> [Token] {
    return expression
  }
}


// --------------

public struct StackToken<T> {
	fileprivate var array = [T]()
	public var isEmpty: Bool { return array.isEmpty }
	public var count: Int { return array.count }
	public mutating func push(_ element: T) { array.append(element) }	
	public mutating func pop() -> T? { return array.popLast() }
	public var top: T? { return array.last }
}

extension StackToken: Sequence {
	public func makeIterator() -> AnyIterator<T> {
		var curr = self
        return AnyIterator { return curr.pop() }
	}
}

public func reversePolishNotation(_ expression: [Token]) -> String {
  var tokenStack = StackToken<Token>()
  var reversePolishNotation = [Token]()

  for token in expression {
    switch token.tokenType {
    case .operand(_): reversePolishNotation.append(token)
    case .openBracket: tokenStack.push(token)
    case .closeBracket:
      while tokenStack.count > 0, let tempToken = tokenStack.pop(), !tempToken.isOpenBracket {
        reversePolishNotation.append(tempToken)
      }
    case .Operator(let operatorToken):
      for tempToken in tokenStack.makeIterator() {
        if !tempToken.isOperator { break }

        if let tempOperatorToken = tempToken.operatorToken {
          if operatorToken.associativity == .leftAssociative && operatorToken <= tempOperatorToken
            || operatorToken.associativity == .rightAssociative && operatorToken < tempOperatorToken {
            reversePolishNotation.append(tokenStack.pop()!)
          
            } else { break }
        }
      }
      tokenStack.push(token)
    }
  }

  while tokenStack.count > 0 { reversePolishNotation.append(tokenStack.pop()!) }
  return reversePolishNotation.map({token in token.description}).joined(separator: " ")
}


// -------------- 

enum OperatorAssociativity { case leftAssociative, rightAssociative }

public enum OperatorType: CustomStringConvertible {
  case add, subtract, divide, multiply, power

  public var description: String {
    switch self {
    case .add: return "+"
    case .subtract: return "-"
    case .divide: return "/"
    case .multiply: return "*"
    case .power: return "^"
    }
  }
}

public enum TokenType: CustomStringConvertible {
  case openBracket
  case closeBracket
  case Operator(OperatorToken)
  case operand(Double)

  public var description: String {
    switch self {
    case .openBracket: return "("
    case .closeBracket: return ")"
    case .Operator(let operatorToken): return operatorToken.description
    case .operand(let value): return "\(value)"
    }
  }
}

public struct OperatorToken: CustomStringConvertible {
  let operatorType: OperatorType
  public var description: String { operatorType.description }

  init(operatorType: OperatorType) { self.operatorType = operatorType }

  var precedence: Int {
    switch operatorType {
    case .add, .subtract: return 10
    case .divide, .multiply: return 20
    case .power: return 30
    }
  }
    
  var associativity: OperatorAssociativity {
    switch operatorType {
    case .add, .subtract, .divide, .multiply, .power: return .leftAssociative
    default: return .rightAssociative
    }
  }

}

func <= (left: OperatorToken, right: OperatorToken) -> Bool { return left.precedence <= right.precedence }
func < (left: OperatorToken, right: OperatorToken) -> Bool { return left.precedence < right.precedence }


public struct Token: CustomStringConvertible {
  let tokenType: TokenType
  public var description: String { tokenType.description }

  init(tokenType: TokenType) { self.tokenType = tokenType }
  init(operand: Double) { tokenType = .operand(operand) }
  init(operatorType: OperatorType) { tokenType = .Operator(OperatorToken(operatorType: operatorType)) }

  var isOpenBracket: Bool {
    switch tokenType {
    case .openBracket: return true
    default: return false
    }
  }

  var isOperator: Bool {
    switch tokenType {
    case .Operator(_): return true
    default: return false
    }
  }

  var operatorToken: OperatorToken? {
    switch tokenType {
    case .Operator(let operatorToken): return operatorToken
    default: return nil
    }
  }
}


// -------------- 

func evalRPN(_ expr: String) -> Double {
    guard expr.count > 0 else { return 0.0 }
    var stack: [Double] = []
    
    for token in expr.components(separatedBy: " ") {
	if let tokenNum = Double(token) { stack.append(tokenNum) }
        
    else if token == OperatorType.divide.description {
        let rhs = stack.removeLast()
        let lhs = stack.removeLast()
        stack.append(lhs / rhs)
    }
    else if token == OperatorType.multiply.description {
        let rhs = stack.removeLast()
        let lhs = stack.removeLast()
        stack.append(lhs * rhs)
    }
    else if token == OperatorType.subtract.description {
        let rhs = stack.removeLast()
        let lhs = stack.removeLast()
        stack.append(lhs - rhs)
    }
    else if token == OperatorType.add.description {
        let rhs = stack.removeLast()
        let lhs = stack.removeLast()
        stack.append(lhs + rhs)
    }
    else if token == OperatorType.power.description {
        let rhs = stack.removeLast()
        let lhs = stack.removeLast()
        stack.append(pow(lhs, rhs))
        }
    }
    return stack.removeLast()
}


// -------------- 

let str = "1 + 2.2 * 3 + ( 2 * 2 ) ^ 3"
print(evalArithmeticExpression(str))

