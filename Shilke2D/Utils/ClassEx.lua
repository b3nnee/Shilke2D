--[[---
Class.lua
Compatible with Lua 5.1 (not 5.0).

Used to implements simple object oriented logic in lua, with single inheritance 
and interface implementation.

@usage

- class can be used to define base classes and derived classes:

A = class()
B = class(A)

b = B()
b:is_a(A) == true
class_type(b) == A -> false
class_type(b) == B -> true

- Multiple inheritance is not allowed, but it's possible to define 
interfaces (always using class) and to require that a class implements them:

iC = class()
D = class(B,iC)

d = D()
d:is_a(A) = true
d:is_a(B) = true
d:is_a(iC) = false
d:is_a(D) = true
d:implements(iC) = true

- It's also possible to implements one or more interfaces without inheritance:

iE = class()
F = class(nil,iC,iE)

f = F()
f:is_a(iC) = false
f:implements(iC) = true
f:implements(iE) = true
--]]


local reserved =
{
    __index            = true,
    _base              = true,
    init               = true,
    is_a               = true,
    implements         = true
}

--[[---
Offers a way to check if an obj is of a specific class
@param o the object to be testet
@return the 'type' of the object if is a class type
@usage
A = class()
B = class(A)

b = B()

class_type(b) == A -> false
class_type(b) == B -> true
--]]
function class_type(o)
	local t = type(o)
	--classes are tables
	if t ~= 'table' then return nil end
	--classes must have a is_a function defined
	if not o.is_a then return nil end
	return getmetatable(o)
end

--[[---
Creates a new class type, allowing single inheritance and multiple interface implementation
@param ... p1 is a base class for inheritance (can be null), following are interface to implement 
--]]
function class(...)
    
    local c = {}    -- a new class instance

    local args = {...}
    if table.getn(args) then
        
        local base = args and args[1] or nil
        
        if type(base) == 'table' then
            -- our new class is a shallow copy of the base class!
            for i,v in pairs(base) do
                c[i] = v
            end
            c._base = base
        end
        
        table.remove(args,1)
        
        for _,i in pairs(args) do
            if type(i) =='table' then
                for k,v in pairs(i) do
                    if not reserved[k] and type(i[k]) == 'function' then
                        if c[k] then
                            print("warning " .. k .. 
                                " is already defined")
                        end
                        c[k] = v
                    end
                end
            end
        end
    end    

    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c

    -- expose a constructor which can be called by <classname>( <args> )
    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj,c)
        if class_tbl.init then
            class_tbl.init(obj,...)
        else 
            -- make sure that any stuff from the base class is 
            --initialized!
            if base and base.init then
                base.init(obj, ...)
            end
        end

        return obj
    end

	---allows to check if a class inherits from another
    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do 
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    
	---allows to check if a class implements a specific interface
    c.implements = function(self, interface)
            -- Check we have all the target's callables
        for k, v in pairs(interface) do
            if not reserved[k] and type(v) == 'function' and 
                type(self[k]) ~= 'function' then
                return false
            end
        end
        return true
    end

    setmetatable(c, mt)
    return c
end