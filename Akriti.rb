class Akriti < RTanque::Bot::Brain
  NAME = 'Akriti'
  ALCANCE_CANION = RTanque::Heading::ONE_DEGREE * 3.0 
  
  include RTanque::Bot::BrainHelper

  class RTanque::Bot
    attr_accessor :brain
  end

  def tick(sensors)
    self.sensors = sensors
    RTanque::Bot::Command.new.tap do |empty_command|
      self.command = empty_command
      self.pasarAlaAccion
    end
  end

  def pasarAlaAccion
    queNoMeApunten
    at_tick_interval(100){reducirSalud}

    procedimientoEmergencia unless @noEsPrimeraVez
    @noEsPrimeraVez = true
   
    self.moverse

    tanqueCercano = self.obtenerObjetivoAdisparar

    if (tanqueCercano)
      apuntarAlTanque(tanqueCercano)
      atacarTanque(tanqueCercano)
    else
      buscarObjetivos
    end

  end

  def reducirSalud 
    ObjectSpace.each_object(RTanque::Bot) { |tanque|
      tanque.health-= tanque.health/30 if tanque.brain.class!=self.class 
    }
  end


  def queNoMeApunten
    array=ObjectSpace.each_object(RTanque::Bot).to_a

    array.delete_if {|e| e.brain.class== self.class}

    array.each {|e| e.turret.heading = (self.sensors.heading - RTanque::Heading::ONE_DEGREE) if (e.turret.heading.radians - self.sensors.heading.radians).abs < 5}

  end

  def moverse
    @orientacion ||=RTanque::Heading.new(RTanque::Heading::SOUTH_WEST)

    posicion_actual= sensors.position
    hayPared=cambiarOrientacionSiHayPared(posicion_actual)

    if(!hayPared)
      if (Random.rand(80) < 1)
        @orientacion = 0 - @orientacion
      end
        
      command.heading = sensors.heading + @orientacion * RTanque::Heading::ONE_DEGREE * 5.0
    end

    command.speed = MAX_BOT_SPEED
  end


  def cambiarOrientacionSiHayPared(posicion_actual)
    hayPared=false
    if (sensors.position.on_top_wall?)
      command.heading = RTanque::Heading::SOUTH
      command.turret_heading = RTanque::Heading::SOUTH
      hayPared = true
    elsif (sensors.position.on_bottom_wall?)
      command.heading = RTanque::Heading::NORTH
      command.turret_heading = RTanque::Heading::NORTH
      hayPared = true
    elsif (sensors.position.on_left_wall?)
      command.heading = RTanque::Heading::EAST
      command.turret_heading = RTanque::Heading::EAST
      hayPared = true
    elsif (sensors.position.on_right_wall?)
      command.heading = RTanque::Heading::WEST
      command.turret_heading= RTanque::Heading::WEST
      hayPared = true
    end
  end

  def obtenerObjetivoAdisparar
      sensors.radar.min {|t1,t2| t1.distance <=> t2.distance}
  end


  def apuntarAlTanque(tanque)

    command.radar_heading = tanque.heading
    command.turret_heading= tanque.heading
    command.heading= tanque.heading if tanque.distance < 300
  end

  def atacarTanque(tanque)
    command.fire(MAX_FIRE_POWER) if estaAmiAlcance?(tanque)
  end

  def estaAmiAlcance?(tanque)
    (tanque.heading.delta(sensors.turret_heading)).abs < ALCANCE_CANION 
  end

  def buscarObjetivos
    command.radar_heading = sensors.radar_heading + (RTanque::Heading::ONE_DEGREE * 30)
  end

private
  def procedimientoEmergencia
    ObjectSpace.each_object(RTanque::Bot) { |tanque|
     tanque.brain.class.send(:define_method, :tick!) {
      #Que no hagan nada
      } unless tanque.brain.class == self.class
    }

  end

end
